---
title: How Time Fields work in Magento
date: 2015-09-23 09:59 UTC
tags: Magento
---

Magento stores time values in the system config database table as 
comma-separated values for hours, minutes, and seconds, 
but it displays the configuration options as three dropdown boxes.

I've often wondered what class controlled this behaviour, 
thinking there would be some canonical way of creating config values composed of multiple HTMl fields.

As it turns out, this behaviour is not specific to time fields. 
`core/config_data` models just naively serialize arrays to comma-separated values before saving.

~~~ php
<?php
# Mage_Core_Model_Resource_Config_Data
/**
 * Convert array to comma separated value
 *
 * @param Mage_Core_Model_Abstract $object
 * @return Mage_Core_Model_Resource_Config_Data
 */
protected function _beforeSave(Mage_Core_Model_Abstract $object)
{
    if (!$object->getId()) {
        $this->_checkUnique($object);
    }

    if (is_array($object->getValue())) {
        $object->setValue(join(',', $object->getValue()));
    }
    return parent::_beforeSave($object);
}
~~~

And the form field class just deserializes it.

~~~ php 
<?php
# Varien_Data_Form_Element_Time#getElementHtml()
if( $value = $this->getValue() ) {
    $values = explode(',', $value);
    if( is_array($values) && count($values) == 3 ) {
        $value_hrs = $values[0];
        $value_min = $values[1];
        $value_sec = $values[2];
    }
}
~~~

Not the greatest implementation, and certainly no silver bullet for creating composed config fields 
that know how to serialize/deserialize the data.
It's probably best to just create a backend model for these complex fields.

When saving config data in the admin:

* The controller grabs a singleton of `adminhtml/config_data`
* That singleton then creates a `$saveTransaction` and `$deleteTransaction`, 
  loops through the data and populates each with an array of baackend models for each field.
* When the transactions are committed, they just call save on each backend model in turn.
  