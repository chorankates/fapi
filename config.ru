require 'sinatra'

set :environment, :production
disable :run

require File.expand_path(File.join(File.dirname(__FILE__), 'fapi'))
run Sinatra::Application