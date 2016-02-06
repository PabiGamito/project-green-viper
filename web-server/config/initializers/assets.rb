Rails.application.config.assets.precompile += %w( bootstrap.min.css )
Rails.application.config.assets.precompile += %w( bootstrap.min.js )
Rails.application.config.assets.precompile += %w( jquery.js )

#Landing
Rails.application.config.assets.precompile += %w( frontend/plugins.css )
Rails.application.config.assets.precompile += %w( frontend/main.css )
Rails.application.config.assets.precompile += %w( frontend/themes.css )
Rails.application.config.assets.precompile += %w( frontend/plugins.js )
Rails.application.config.assets.precompile += %w( frontend/app.js )