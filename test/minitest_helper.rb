$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'life_guard'
require 'byebug'
ENV['RAILS_ENV'] = 'test'
require 'minitest/autorun'
require 'mocha/setup'
require 'active_record'
