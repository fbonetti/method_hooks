require 'spec_helper'
require 'pry'

describe MethodHooks do

  before do
    Object.send(:remove_const, :Base) if Object.const_defined?(:Base)

    class Base
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

  it 'should call the before block' do
    Base.class_eval do
      attr_reader :events

      def initialize
        @events = []
      end

      def save
        @events << 'save'
      end
    end

    Base.instance_eval do
      before(:save) { @events << 'before' }
    end

    base = Base.new
    base.save

    expect(base.events).to eq(['before', 'save'])
  end

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

  it 'should call the after block' do
    Base.instance_eval do
      after(:save) { @events << 'after' }
    end

    base = Base.new
    base.save

    expect(base.events).to eq(['save', 'after'])
  end

end
