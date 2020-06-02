class Year < ApplicationRecord
  belongs_to :segment
  belongs_to :stage
  has_many :answer_book
  has_many :activity_sequences
  has_many :learning_objectives

  validates :name, presence: true

  after_save :activity_sequence_reindex

  class << self

    def all_or_with_year(stage_id = nil)
      return [] unless stage_id
      where(stage_id: stage_id)
    end
  end

  private

  def activity_sequence_reindex
    ActivitySequence.reindex(async: true)
  end
end
