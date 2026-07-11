class Recurring::GenerateOpenGraphImageJob < ApplicationJob
  queue_as :low

  def perform
    OpenGraphImage.generate!
  end
end
