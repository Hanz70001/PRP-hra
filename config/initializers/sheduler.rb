Rails.application.config.after_initialize do
  Thread.new do
    CyclicLoop.ContextDisposal
  end

  Thread.new do
    CyclicLoop.gameTick
  end
end