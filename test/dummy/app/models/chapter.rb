class Chapter < ApplicationRecord
  belongs_to :course, optional: true
end
