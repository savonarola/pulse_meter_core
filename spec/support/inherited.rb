class ParentDummy
  def instance_method; "parent#instance"; end
  def instance_method_i; "parent#instance_i"; end
  def only_parent_method; "parent#only_parent"; end
  def only_parent_method_i; "parent#only_parent_i"; end
  def self.class_method; "parent.class"; end
  def self.only_parent_class_method; "parent.class"; end
  def self.class_method_i; "parent.class_i"; end
  def self.only_parent_class_method_i; "parent.class_i"; end
  def self.metaclass; class << self; self; end; end
end
class ChildDummy < ParentDummy
  def instance_method; "child#instance"; end
  def instance_method_i; "child#instance_i"; end
  def self.class_method; "child.class"; end
  def self.class_method_i; "child.class_i"; end
end
