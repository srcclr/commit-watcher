require 'citrus'

Citrus.load 'boolean'

m = Boolean.parse 'false or true'
puts m.value

m = Boolean.parse 'true and (!true && True) || FALSE'
puts m.value
