class CompositeTask < ApplicationRecord
  self.primary_key = %i[account_id task_id]
end
