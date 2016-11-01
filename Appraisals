%w(3.2 4.0 4.1 4.2 5.0).each do |version|
  appraise "rails.#{version}.activerecord" do
    gem 'activerecord', "~> #{version}.0"
    gem 'activesupport', "~> #{version}.0"
    gem 'activejob', "~> #{version}.0" if version >= '4.2'
    gem 'resque', require: false
    gem 'sidekiq', require: false
  end

  appraise "rails.#{version}.activerecord.kaminari" do
    gem 'activerecord', "~> #{version}.0"
    gem 'activesupport', "~> #{version}.0"
    gem 'activejob', "~> #{version}.0" if version >= '4.2'
    gem 'actionpack', "~> #{version}" if version >= '5.0'
    gem 'kaminari', '0.16.3', require: false
  end

  appraise "rails.#{version}.activerecord.will_paginate" do
    gem 'activerecord', "~> #{version}.0"
    gem 'activesupport', "~> #{version}.0"
    gem 'activejob', "~> #{version}.0" if version >= '4.2'
    gem 'will_paginate', require: false
  end
end

%w(4.0 4.1 4.2).each do |activesupport|
  %w(4.0.0 5.1.0).each do |mongoid|
    appraise "rails.#{activesupport}.mongoid.#{mongoid}" do
      gem 'mongoid', "> #{mongoid}"
      gem 'activesupport', "~> #{activesupport}.0"
      gem 'resque', require: false
      gem 'sidekiq', require: false
    end

    appraise "rails.#{activesupport}.mongoid.#{mongoid}.kaminari" do
      gem 'mongoid', "> #{mongoid}"
      gem 'activesupport', "~> #{activesupport}.0"
      gem 'kaminari', '0.16.3', require: false
    end

    appraise "rails.#{activesupport}.mongoid.#{mongoid}.will_paginate" do
      gem 'mongoid', "> #{mongoid}"
      gem 'activesupport', "~> #{activesupport}.0"
      gem 'will_paginate', require: false
    end
  end
end

appraise "sequel.4.31" do
  gem 'sequel', "~> 4.31.0"
  gem 'activesupport', '~> 4.2.0'
end
