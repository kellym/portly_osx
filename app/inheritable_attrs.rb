# Based off of Rails, by way of http://www.raulparolari.com/Rails/class_inheritable

class Class
 def class_inheritable_reader(*syms)
  syms.each do |sym|
   define_singleton_method sym.to_sym do
      read_inheritable_attr(sym.to_sym)
   end
  end
 end

 def class_inheritable_writer(*syms)
  syms.each do |sym|
    define_singleton_method :"#{sym}=" do |obj|
      write_inheritable_attr(sym.to_sym,obj)
    end
   end
 end

  def class_inheritable_accessor(*syms)
    class_inheritable_reader(*syms)
    class_inheritable_writer(*syms)
  end

  # accessor for hash
  def inheritable_attrs
    @inheritable_attrs ||= {}
  end

  # write variable into hash
  def write_inheritable_attr(key, value)
    inheritable_attrs[key] = value
  end

  # read variable from hash
  def read_inheritable_attr(key)
    inheritable_attrs[key]
  end

  private

  def inherited_with_inheritable_attrs(child)
    inherited_without_inheritable_attrs(child) if respond_to?(:inherited_without_inheritable_attrs)

    if inheritable_attrs.nil?
      new_inheritable_attrs = {}
    else
      new_inheritable_attrs = inheritable_attrs.inject({}) do |memo,(key, value)|
        memo.update(key => (value.dup rescue value))
      end
    end
    child.instance_variable_set('@inheritable_attrs', new_inheritable_attrs)
  end
end
