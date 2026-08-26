module Ui
  # A dashed rule and a plain statement — the archive is genuinely
  # incomplete, and saying so is more credible than an illustration.
  class EmptyStateComponent < ApplicationComponent
    renders_one :action

    def initialize(title:, body: nil)
      @title = title
      @body = body
    end

    private

    attr_reader :title, :body
  end
end
