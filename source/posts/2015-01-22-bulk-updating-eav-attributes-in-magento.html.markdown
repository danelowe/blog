---
title: Bulk updating EAV attributes in Magento
date: 2015-01-22 11:52 UTC
tags: Magento
---

## Don't fear the EAV
EAV in Magento is a pain. It's slow and difficult to manage. But it's not going away.

Sometimes (well, all of the time) I wish there was a PostgreSQL adapter for Magento and it did away with EAV for one of
the many features (HSTORE, JSON field queries) Postgres has that makes EAV in Magento's case unecessary. I think that is
a project for another day.

Right now. There are many situations where data just needs to be stored in an EAV attribute.
Sorting, for example, is designed in such a way that you really need an attribute to sort by.
This is especially the case if you use the Bubble_ElasticSearch extension, or perhaps other engines.
If you try to add a sort option that isn't an attribute, you are in for a world of hurt and a lot of nasty hacks.
Sometimes you really just need to quickly update some EAV attributes for a bunch of products at once.

So, in this post, we will be working towards creating an indexing process that grabs some data from a query and
efficiently updates that data as EAV values against each product.
The attribute we will be updating is called sale_count, and represents the number of times the product has been sold,
taking into account the state of the orders.

## Create the EAV attribute.
Here is some example content for a migration script to create the attribute.

~~~ php
<?php
//install-0.1.0.php
$installer = $this;
/* @var $installer Mage_Core_Model_Resource_Setup */
$installer->startSetup();
$attr = array (
    'type' => 'int',
    'backend' => '',
    'frontend' => '',
    'label' => 'Sale Count',
    'input' => 'text',
    'global' => Mage_Catalog_Model_Resource_Eav_Attribute::SCOPE_STORE,
    'is_visible' => false,
    'is_configurable' => true,
    'used_in_product_listing' => true,
    'required' => false,
    'default' => 0,
);
$installer->addAttribute('catalog_product','sale_count',$attr);
$installer->updateAttribute('catalog_product', 'sale_count', 'used_in_product_listing', 1);
$installer->updateAttribute('catalog_product', 'sale_count', 'is_visible', 0);
$installer->updateAttribute('catalog_product', 'sale_count', 'used_for_sort_by', 1);
$installer->endSetup();
~~~

## Updating EAV data in bulk.

As far as I know, Magento has no built in method to bulk update EAV attributes for many products with different values.
I would be extremely happy if someone could prove me wrong.

For now, we can use a method similar to this one on a resource model.

~~~ php
<?php
/**
 * Update EAV table with data from an array
 *
 * @param array $data 
 *   a 3d array with entity_id and value as keys for each row, e.g. array(array('entity_id' => 1, 'value' => 'test'))
 * @return $this
 */
protected function _updateEavTable($data)
{
    if (!empty($data)) {
        $attributeModel = Mage::getModel('eav/entity_attribute')->loadByCode('catalog_product', 'sale_count');
        $attributeData = array(
            'entity_type_id' => $attributeModel->getEntityTypeId(),
            'attribute_id' => $attributeModel->getAttributeId()
        );
        $tableData = array();
        foreach ($data as $_row) {
            $tableData[] =  array_merge($_row, $attributeData);
        }
        $adapter = $this->_getWriteAdapter();
        $tableName = $attributeModel->getBackendTable();
        $adapter->insertOnDuplicate($tableName, $tableData, array('value'));
    }
    return $this;
}
~~~

What this does is simply get the attribute model, find out what the entity_type_id and attribute_id should be,
then update the backend table for that attribute. 

Note the use of insertOnDuplicate(). This will do an upsert, which in MySQL is will be an 
INSERT ... ON DUPLICATE KEY UPDATE. The array('value') parameter in this method call means that the query is constructed in such a
way that if a duplicate key is encountered (the product already has a value for this attribute) during the insert, 
that column in row will simply be updated. The resulting SQL will be similar to:

~~~ sql
INSERT INTO `catalog_product_entity_int` (`store_id`,`entity_id`,`value`,`entity_type_id`,`attribute_id`) 
VALUES (?, ?, ?, ?, ?), (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`) 
~~~

Nice and simple, huh. Knowing how Magento EAV attributes work, and being armed with simple snippets like this can open
up a lot of doors when managing data in Magento. 
 
Notice how the $data parameter asks for a slightly more complex array than it needs to. 
 Why doesn't it just ask for a 2D array with the product ID as key, and the value as, well, the value of the
 array element? 
 You could adjust the method a bit to do that, but in this case I want to update the EAV attribute values directly
 from an SQL query, which is what the next method is all about.
 
## Updating the data from an SQL method. 

Assume we have an SQL query that returns rows of data with two columns:

* entity_id - The product ID
* value - The value of the EAV attribute as we want to store it in the database

Well, now it is simple to update the EAV data from that query. 
All we have to do is pass the data returned from that query to the method we created above.
But first we want to put a guard in there to prevent updating too many rows at once.
The algorithm for this particular guard was lifted from Magento core. 

~~~ php
<?php
/**
 * Update EAV Table with data from select;
 *
 * @param Zend_Db_Select $select that returns rows with one column named 'entity_id', and the other named 'value'
 * @return $this
 */
protected function _updateFromSelect(Zend_Db_Select $select)
{
    $query   = $this->_getReadAdapter()->query($select);
    $i      = 0;
    $data   = array();
    while ($_row = $query->fetch(PDO::FETCH_ASSOC)) {
        $i ++;
        $data[] = $_row;
        if (($i % 1000) == 0) {
            $this->_updateEavTable($data);
            $data = array();
        }
    }
    return $this->_updateEavTable($data);
}
~~~

Have a look at the below method for an example of such a select object.

~~~ php
<?php
/**
 * Get a Select object to update the data from
 *
 * @param array $productIds
 * @return Varien_Db_Select|Zend_Db_Select
 */
protected function _getSelect($productIds)
{
    $select = Mage::getModel('sales/order')->getCollection()->getSelect()
        ->reset(Zend_Db_Select::COLUMNS)
        ->columns('store_id')
        ->joinLeft(
            array('items' => $this->getTable('sales/order_item')),
            'main_table.entity_id = items.order_id',
            array(new Zend_Db_Expr('product_id as entity_id'), new Zend_Db_Expr('sum(qty_ordered) as value'))
        )
        ->where("main_table.created_at > DATE_FORMAT(NOW() - INTERVAL 3 MONTH, '%Y-%m-01')")
        ->where("main_table.status IN ('complete', 'processing', 'closed')")
        ->group(array('items.product_id', 'main_table.store_id'))
    ;
    if ($productIds) {
        $select->where('items.product_id IN (?)', $productIds);
    }
    return $select;
}
~~~

## Making it legit

OK, so now we have an SQL query to get the data we want from the database, 
and the means to insert that data as EAV attributes for each product. 
All that is left is turning this code into a legitimate Magento indexer.

In true Magento style, the boilerplate code here can seem a little unwieldy, but makes sense once you study it.

### The Resource Model

All of the code we have looked at so far operates on the database, so it belongs in a resource model.

In this case, the ability to update an EAV attribute in bulk is so useful in the indexing processes I am creating
that I want to make it re-usable. The obvious first step here is to create an abstract class with the re-usable code.

~~~ php
<?php
abstract class MyNamespace_MyModule_Model_Resource_Indexer_Eav_Abstract
    extends Mage_Catalog_Model_Resource_Product_Indexer_Abstract
{
    protected $_attributeCode;
    protected $_entityTypeCode = 'catalog_product';

    /**
     * Reindex All
     *
     * @return $this
     * @throws Exception
     */
    public function reindexAll()
    {
        return $this->reindexProductIds();
    }

    /**
     * Reindex data for a set of product IDs
     *
     * @param null|array $productIds
     * @return $this
     * @throws Exception
     */
    public function reindexProductIds($productIds = null)
    {
        $this->useIdxTable(true);
        $this->beginTransaction();
        try {
            $this->_updateFromSelect($this->_getSelect($productIds));
            $this->commit();
        } catch (Exception $e) {
            $this->rollBack();
            throw $e;
        }
        return $this;
    }

    /**
     * Get The Select that has data for the product IDs
     * Should have entity_id as one column, and value as the next
     *
     * @param array $productIds
     * @return Zend_Db_Select
     */
    abstract protected function _getSelect($productIds);

    /**
     * Update EAV Table with data from select;
     *
     * @param Zend_Db_Select $select that returns rows with one column named 'entity_id', and the other named 'value'
     * @return $this
     */
    protected function _updateFromSelect(Zend_Db_Select $select)
    {
        $query   = $this->_getReadAdapter()->query($select);
        $i      = 0;
        $data   = array();
        while ($_row = $query->fetch(PDO::FETCH_ASSOC)) {
            $i ++;
            $data[] = $_row;
            if (($i % 1000) == 0) {
                $this->_updateEavTable($data);
                $data = array();
            }
        }
        return $this->_updateEavTable($data);
    }

    /**
     * Update EAV table with data from an array
     *
     * @param $data
     * @return $this
     */
    protected function _updateEavTable($data)
    {
        if (!empty($data)) {
            $attributeModel = $this->_getAttributeModel();
            $attributeData = array(
                'entity_type_id' => $attributeModel->getEntityTypeId(),
                'attribute_id' => $attributeModel->getAttributeId()
            );
            $tableData = array();
            foreach ($data as $_row) {
                $tableData[] =  array_merge($_row, $attributeData);
            }
            $adapter = $this->_getWriteAdapter();
            $tableName = $attributeModel->getBackendTable();
            $adapter->insertOnDuplicate($tableName, $tableData, array('value'));
        }
        return $this;
    }

    /**
     * Get Attribute Model
     *
     * @return Mage_Eav_Model_Entity_Attribute_Abstract
     * @throws Mage_Core_Exception
     */
    protected function _getAttributeModel()
    {
        return Mage::getModel('eav/entity_attribute')->loadByCode($this->_entityTypeCode, $this->_attributeCode);
    }

}
~~~

So to create the Resource model for the particular indexer, we can just define the SQL query and a few variables.

~~~ php
<?php
class MyNamespace_MyModule_Model_Resource_Indexer_SaleCount
    extends MyNamespace_MyModule_Model_Resource_Indexer_Eav_Abstract
{
    protected $_attributeCode = 'sale_count';

    /**
     * Initialize connection and define main table
     *
     */
    protected function _construct()
    {
        $this->_init('mynamespace_mymodule/index_product_data', 'product_id');
    }

    public function incrementProductSaleCount($productIds, $storeId)
    {
        // Run an SQL query to update the attribute on the products whenever an order is placed
    }

    /**
     * Get a Select object to update the data from
     *
     * @param array $productIds
     * @return Varien_Db_Select|Zend_Db_Select
     */
    protected function _getSelect($productIds)
    {
        $select = Mage::getModel('sales/order')->getCollection()->getSelect()
            ->reset(Zend_Db_Select::COLUMNS)
            ->columns('store_id')
            ->joinLeft(
                array('items' => $this->getTable('sales/order_item')), 
                'main_table.entity_id = items.order_id', 
                array(new Zend_Db_Expr('product_id as entity_id'), new Zend_Db_Expr('sum(qty_ordered) as value'))
            )
            ->where("main_table.created_at > DATE_FORMAT(NOW() - INTERVAL 3 MONTH, '%Y-%m-01')")
            ->where("main_table.status IN ('complete', 'processing', 'closed')")
            ->group(array('items.product_id', 'main_table.store_id'))
        ;
        if ($productIds) {
            $select->where('items.product_id IN (?)', $productIds);
        }
        return $select;
    }
} 
~~~

## The Indexer Model
The gist of indexer models is that a Mage_Index_Model_Event is matched, 
giving the indexer model a chance to decide if it wants to do something with the event or not.
If the indexer matches the event, it would usually  the register itself, storing some data about the event.
Then in due course the indexer processes the event, 
loading the stored data and running an index process using that data.
Because the process of indexing is essentially moving data around, it is often done in the database and hence passed
off to a resource model behind the indexer model.

~~~ php
<?php
class MyNamespace_MyModule_Model_Indexer_SaleCount extends Mage_Index_Model_Indexer_Abstract
{
    /**
     * Data key for matching result to be saved in
     */
    const EVENT_MATCH_RESULT_KEY = 'mynamespace_mymodule_index_sale_count_match_result';


    /**
     * @var array
     */
    protected $_matchedEntities = array(
        Mage_Sales_Model_Order::ENTITY => array(
            'create'
        )
    );

    /**
     * Initialize resource model
     *
     */
    protected function _construct()
    {
        $this->_init('mynamespace_mymodule/indexer_saleCount');
    }

    /**
     * Retrieve Indexer name
     *
     * @return string
     */
    public function getName()
    {
        return Mage::helper('mynamespace_mymodule')->__('Product Sale Count (EAV)');
    }

    /**
     * Retrieve Indexer description
     *
     * @return string
     */
    public function getDescription()
    {
        return Mage::helper('mynamespace_mymodule')->__('Set the number of sales for each product in an EAV attribute');
    }

    /**
     * Register data required by process in event object
     *
     * @param Mage_Index_Model_Event $event
     */
    protected function _registerEvent(Mage_Index_Model_Event $event)
    {
        /** @var Mage_Sales_Model_Order $order */
        $order = $event->getDataObject();
        $ids = array();
        foreach ($order->getAllItems() as $_item) {
            $ids[] = $_item->getProductId();
        }
        $event->addNewData('mynamespace_mymodule_index_sale_count_product_ids', $ids);
        $event->addNewData('mynamespace_mymodule_index_sale_count_store_id', $order->getStoreId());
    }

    public function matchEvent(Mage_Index_Model_Event $event)
    {
        $data = $event->getNewData();
        if (isset($data[self::EVENT_MATCH_RESULT_KEY])) {
            return $data[self::EVENT_MATCH_RESULT_KEY];
        }
        $entity = $event->getEntity();
        $result = true;
        if($entity != Mage_Sales_Model_Order::ENTITY){
            return;
        }
        $event->addNewData(self::EVENT_MATCH_RESULT_KEY, $result);
        return $result;
    }

    /**
     * Process event
     *
     * @param Mage_Index_Model_Event $event
     */
    protected function _processEvent(Mage_Index_Model_Event $event)
    {
        $data = $event->getNewData();
        if(!empty($data['mynamespace_mymodule_index_sale_count_product_ids'])){
            $this->getResource()->incrementProductSaleCount(
                $data['mynamespace_mymodule_index_sale_count_product_ids'],
                $data['mynamespace_mymodule_index_sale_count_store_id']
            );
        }
    }
}
~~~

## But Magento doesn't have an index event for Order Place!

Well, now it does...

~~~ php
<?php
class MyNamespace_MyModule_Model_Observer
{
    /**
     * Reindex on Order Place
     *
     * Hook on order place to allow reindexing of top-sellers and product_revenue
     * @param $observer
     */
    public function reindexOrderPlace($observer)
    {
        $order = $observer->getEvent()->getOrder();
        Mage::getSingleton('index/indexer')->processEntityAction(
            $order, Mage_Sales_Model_Order::ENTITY, 'create'
        );
    }
}
~~~


## The Config

How does Magento know to send the Index events to the indexer model? 
The model is registered as an indexer in your module config. Yay, more config to learn!

~~~ xml
<?xml version="1.0" encoding="UTF-8"?>
<config>
    <modules>
        <MyNamespace_MyModule>
            <version>0.1.0</version>
        </MyNamespace_MyModule>
    </modules>

    <global>
    
        <models>
            <mynamespace_mymodule>
                <class>MyNamespace_MyModule_Model</class>
                <resourceModel>mynamespace_mymodule_resource</resourceModel>
            </mynamespace_mymodule>
            <mynamespace_mymodule_resource>
                <class>MyNamespace_MyModule_Model_Resource</class>
            </mynamespace_mymodule_resource>
        </models>

        <resources>
            <mynamespace_mymodule_setup>
                <setup>
                    <module>MyNamespace_MyModule</module>
                    <class>Mage_Eav_Model_Entity_Setup</class>
                </setup>
                <connection>
                    <use>core_setup</use>
                </connection>
            </mynamespace_mymodule_setup>
        </resources>

        <events>
            <sales_order_place_after>
                <observers>
                    <avid_mynamespace_mymodule_reindex_order_place>
                        <class>mynamespace_mymodule/observer</class>
                        <method>reindexOrderPlace</method>
                    </avid_mynamespace_mymodule_reindex_order_place>
                </observers>
            </sales_order_place_after>
        </events>

        <index>
            <indexer>
                <!-- Indexer name is stored in database, with limited characters -->
                <!-- Don't make the name too long or you might get strange errors -->
                <tt_catalog_saleCount>
                    <model>mynamespace_mymodule/indexer_saleCount</model>
                </tt_catalog_saleCount>
            </indexer>
        </index>

    </global>
</config>
~~~

P.S. Please leave empty lines between blocks of XML. Those using Vim or IdeaVim will understand all too well. 

## Further refactoring.
Composition over inheritance. Well, that's not so easy with PHP and Magento especially. 
But, if the ability to update EAV attributes in bulk is so cool that we want to reuse it in places other than Indexers
we don't want the logic sitting in the Resource Model for an indexer do we?
The logic needs to be in one place that is accessible everywhere. In Magento, that could mean:

* A Helper
* A Service Object
* Somewhere else

Which would you choose, and why?