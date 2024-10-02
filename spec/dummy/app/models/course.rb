class Course < ApplicationRecord
  has_many :chapters, dependent: :destroy
end
