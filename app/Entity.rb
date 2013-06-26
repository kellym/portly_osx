#
#  Entity.rb
#  port
#
#  Created by Kelly Martin on 3/11/13.
#  Copyright 2013 Kelly Martin. All rights reserved.
#

class Entity < NSManagedObject
  class_inheritable_accessor :entity_name
  self.entity_name = 'Entity'

  def self.inherited(sub)
    sub.entity_name = sub.to_s
  end

  def self.find_first(context, options={})
    pred = extract_predicate(options)
    findFromContext(context, withEntity:entity_name, andPredicate:pred, options:options.merge(limit:1)).to_a.first
  end

  def self.find_all(context, options={})
    pred = extract_predicate(options)
    findFromContext(context, withEntity:entity_name, andPredicate:pred, options:options)
  end

  def self.findFromContext(context, withEntity:ename, andPredicate:pred, options:options)
    fetchRequest = NSFetchRequest.alloc.init
    entity = NSEntityDescription.entityForName(ename, inManagedObjectContext:context)

    fetchRequest.entity = entity
    fetchRequest.predicate = pred
    fetchRequest.setFetchOffset(options[:offset]) if options[:offset]
    fetchRequest.setFetchLimit(options[:limit]) if options[:limit]
    if options[:order]
      ascending = options[:asc] || true
      sd = NSSortDescriptor.sortDescriptorWithKey(options[:order], ascending:ascending)
      fetchRequest.setSortDescriptors([sd])
    end
    fetchError = Pointer.new_with_type('@')

    context.executeFetchRequest(fetchRequest, error:fetchError)
  end

  def self.extract_predicate(options)
    preds = Array.new
    pred_opt = Array.new
    bylines = Array.new
    options.each_pair do |key, value|
      if key.match(%r{^by_?([a-zA-Z0-9_]+)$})
        search_key = $~[1]
        preds << "#{search_key} = %@"
        pred_opt << value
        bylines << key
      elsif key.to_s == 'conditions'
        preds << value.first
        pred_opt += value[1..-1].to_a
        bylines << key
      end
    end

    if preds.empty?
      return nil
    else
      pred_str = preds.join(' AND ')
      rval = NSPredicate.predicateWithFormat(pred_str, argumentArray:pred_opt)

      # Remove all the 'by' options; we do this now, as any earlier causes problems.
      bylines.each {|by| options.delete(by)}

      return rval
    end
  end
end