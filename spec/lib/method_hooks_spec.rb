require 'spec_helper'

describe MethodHooks do

  before do
    Object.send(:remove_const, :Base) if Object.const_defined?(:Base)

    module AnotherModuleWIthMethodAddedHook
      def method_added(method_name)
        _methods << method_name
        super
      end

      def _methods
        @_methods ||= []
      end
    end

    class Base

      extend AnotherModuleWIthMethodAddedHook
      extend MethodHooks

      attr_reader :events

      def initialize
        @events = []
      end

      def save
        @events << 'save'
      end
    end
  end

  describe '::before' do

    it 'should call the before block' do
      Base.instance_eval do
        before(:save) { @events << 'before' }
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['before', 'save'])
    end

    it 'should allow multiple before hooks on the same method' do
      Base.instance_eval do
        before(:save) { @events << 'first before' }
        before(:save) { @events << 'second before' }
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['first before', 'second before', 'save'])
    end

    it 'should call a method (by name) if no block is given' do
      Base.instance_eval do
        before(:save, :my_method)
      end

      Base.class_eval do
        def my_method
          @events << 'my_method'
        end
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['my_method', 'save'])
    end
  end

  describe '::around' do

    it 'should call the around block' do
      Base.instance_eval do
        around(:save) do |method|
          @events << 'before_around'
          method.call
          @events << 'after_around'
        end
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['before_around', 'save', 'after_around'])
    end

    it 'should call a method (by name) if no block is given' do
      Base.instance_eval do
        around(:save, :my_method)
      end

      Base.class_eval do
        def my_method(method)
          @events << 'before my_method'
          method.call
          @events << 'after my_method'
        end
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['before my_method', 'save', 'after my_method'])
    end
  end

  describe '::after' do

    it 'should call the after block' do
      Base.instance_eval do
        after(:save) { @events << 'after' }
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['save', 'after'])
    end

    it 'should call a method (by name) if no block is given' do
      Base.instance_eval do
        after(:save, :my_method)
      end

      Base.class_eval do
        def my_method
          @events << 'my_method'
        end
      end

      base = Base.new
      base.save

      expect(base.events).to eq(['save', 'my_method'])
    end
  end

  it 'does not override existing .method_added hook' do
    Base.class_eval do
      def some_method
      end
    end

    expect(Base._methods).to include(:some_method)
  end

  describe 'inheritance' do
    before do
      Object.send(:remove_const, :Child) if Object.const_defined?(:Child)
      Object.send(:remove_const, :Grandchild) if Object.const_defined?(:Grandchild)
    end

    it 'should pass parent hooks to the child' do
      Base.instance_eval do
        before(:save) { @events << 'before' }
        
        around(:save) do |method|
          @events << 'before_around'
          method.call
          @events << 'after_around'
        end

        after(:save) { @events << 'after' }
      end

      class Child < Base; end

      child = Child.new
      child.save

      expect(child.events).to eq(['before', 'before_around', 'save', 'after_around', 'after'])
    end

    it 'should not mutate the parent callbacks when a callback is added to a child' do
      Base.instance_eval do
        before(:save) { @events << 'parent before' }
      end

      class Child < Base; end

      Child.instance_eval do
        before(:save) { @events << 'child before' }
      end

      child = Child.new
      child.save
      parent = Base.new
      parent.save

      expect(child.events).to eq(['child before', 'parent before', 'save'])
      expect(parent.events).to eq(['parent before', 'save'])
    end

    it 'should add callbacks to all descendents of a class, recursively' do
      Base.instance_eval do
        before(:save) { @events << 'parent before' }
      end

      class Child < Base; end

      Child.instance_eval do
        before(:save) { @events << 'child before' }
      end

      class Grandchild < Child; end

      Grandchild.instance_eval do
        before(:save) { @events << 'grandchild before' }
      end

      parent = Base.new
      parent.save
      child = Child.new
      child.save
      grandchild = Grandchild.new
      grandchild.save


      expect(parent.events).to eq(['parent before', 'save'])
      expect(child.events).to eq(['child before', 'parent before', 'save'])
      expect(grandchild.events).to eq(['grandchild before', 'child before', 'parent before', 'save'])
    end
  end
end
