class Result < ApplicationRecord
  has_many :links, as: :linkable, dependent: :destroy
  belongs_to :challenge, dependent: :destroy
  belongs_to :teacher, dependent: :destroy

  default_scope { where enabled: true }
end
