class ApplicationRecord < ActiveRecord::Base
  if Rails.version.to_i > 6
    primary_abstract_class
  else
    self.abstract_class = true
  end
end
