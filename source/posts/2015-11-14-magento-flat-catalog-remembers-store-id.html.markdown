---
title: Magento's Flat Catalog Remembers Store ID
date: 2015-11-14 18:53 UTC
tags: Magento
---

If you're using store emulation, and loading product collections while emulating a store,
you need to be aware of one massive gotcha.

**Magento keeps the store id for a flat collection in a _singleton_**

Consider the following code: 

~~~ php 
<?php 
public function reindexAll()
{
    foreach (Mage::app()->getStores() as $_store) {
        $this->_reindex($_store->getId());
    }
}

protected function _reindex($storeId, $products = null)
{
    $initialEnvironment = Mage::getSingleton('core/app_emulation')->startEnvironmentEmulation($storeId);
    $products = Mage::getResourceModel('catalog/product_collection')
        ->setStoreId($storeId)
        ->addStoreFilter($storeId)
    // Do other stuff here.
    Mage::getSingleton('core/app_emulation')->stopEnvironmentEmulation($initialEnvironment);
}
~~~

If the flat catalog is enabled, Magento will try to load products from the first store's flat catalog table
**for all subsequent collections created in the same request**.

Why? Because of this: 

~~~ php
<?php
abstract class Mage_Eav_Model_Entity_Collection_Abstract extends Varien_Data_Collection_Db
{
#...
    /**
     * Standard resource collection initalization
     *
     * @param string $model
     * @return Mage_Core_Model_Mysql4_Collection_Abstract
     */
    protected function _init($model, $entityModel = null)
    {
        $this->setItemObjectClass(Mage::getConfig()->getModelClassName($model));
        if ($entityModel === null) {
            $entityModel = $model;
        }
        $entity = Mage::getResourceSingleton($entityModel);
        $this->setEntity($entity);

        return $this;
    }
#...
~~~

When a flat collection is initialized, `entityModel` is `'catalog/product_flat'`. 
The 'entity' on the collection is set to a singleton of that type. 

Of course, when a singleton is retrieved, it will always return the same instance within the same request. 

When we load the collection, and initialise the select, it gets the flat table name from the entity. 
Given that the entity will always be the first instance constructed in the request, 
it will always use the same table name throughout the request.  

~~~ php
<?php
class Mage_Catalog_Model_Resource_Product_Collection extends Mage_Catalog_Model_Resource_Collection_Abstract
{
#...
    /**
     * Initialize collection select
     * Redeclared for remove entity_type_id condition
     * in catalog_product_entity we store just products
     *
     * @return Mage_Catalog_Model_Resource_Product_Collection
     */
    protected function _initSelect()
    {
        if ($this->isEnabledFlat()) {
            $this->getSelect()
                ->from(array(self::MAIN_TABLE_ALIAS => $this->getEntity()->getFlatTableName()), null)
                ->where('e.status = ?', new Zend_Db_Expr(Mage_Catalog_Model_Product_Status::STATUS_ENABLED));
            $this->addAttributeToSelect(array('entity_id', 'type_id', 'attribute_set_id'));
            if ($this->getFlatHelper()->isAddChildData()) {
                $this->getSelect()
                    ->where('e.is_child = ?', 0);
                $this->addAttributeToSelect(array('child_id', 'is_child'));
            }
        } else {
            $this->getSelect()->from(array(self::MAIN_TABLE_ALIAS => $this->getEntity()->getEntityTable()));
        }
        return $this;
    }
#...
}
~~~

This feels like a very significant bug to me, 
but there is one thing stopping it from entirely preventing multi-store setups. 
PHP generally loads classes and removes them from memory once per request. 
So singletons only last for a single request.

Its not likely that a customer would be using two different stores in a single HTTP request, so it works. 

Which leads to the solution:

* Try not to load collections when emulating stores. Instead, load the collection, then start store emulation. 
* If you must load a collection during store emulation, 
[load it as an EAV collection](/how-to-get-an-eav-product-collection-when-flat-catalog-is-enabled.html)
