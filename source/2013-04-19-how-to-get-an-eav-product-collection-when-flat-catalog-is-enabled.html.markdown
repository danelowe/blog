---
title: How to get an EAV product collection when Flat Catalog is Enabled
date: 2013-04-19 20:14 UTC
tags: Magento
---
There are certain times when your attribute filters just won't work when you're using a flat catalog product collection, namely when you're filtering by multivalued attributes, or attributes not in the index.

This simple fix will allow you to programmatically choose whether the collection should act as an EAV collection or as the default collection specified by admin.

The description assumes you already have an extension set up (of course you already have one set up if you need this)

Create a Resource Model that overloads Mage_Catalog_Model_Resource_Product_Collection

~~~ php
<?php
/**
* Override core Product Collection Model to allow programmatically disabling flat catalog.
*/
class Avid_TTCatalog_Model_Rewrite_Catalog_Resource_Product_Collection extends Mage_Catalog_Model_Resource_Product_Collection
{
    protected $_disableFlat = false;

    public function isEnabledFlat()
    {
        if ($this->_disableFlat)
        return false;
        return parent::isEnabledFlat();
    }

    public function setDisableFlat($value)
    {
        $this->_disableFlat = (boolean)$value;
        $type = $value ? 'catalog/product' : 'catalog/product_flat';
        $this->setEntity(Mage::getResourceSingleton($type));
        return $this;
    }
}
~~~

And of course define the overload in your extension's config.xml

~~~ xml
<?xml version="1.0" encoding="UTF-8"?>
<config>
    <modules>
        <Avid_TTCatalog>
            <version>0.1.0</version>
        </Avid_TTCatalog>
    </modules>
    <global>
        <models>
            <catalog_resource>
                <rewrite>
                    <product_collection>Avid_TTCatalog_Model_Rewrite_Catalog_Resource_Product_Collection</product_collection>
                </rewrite>
            </catalog_resource>
        </models>
    </global>
</config>
~~~

Then, you can disable flat catalog on any product collection immediately after instantiating it, e.g.

~~~ php
<?php
$collection = Mage::getModel('catalog/product')->getCollection()
    ->setDisableFlat(true);
~~~