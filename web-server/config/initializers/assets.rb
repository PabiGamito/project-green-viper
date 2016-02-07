Rails.application.config.assets.precompile += %w( bootstrap.min.css )
Rails.application.config.assets.precompile += %w( bootstrap.min.js )
Rails.application.config.assets.precompile += %w( jquery.js )

#Landing
Rails.application.config.assets.precompile += %w( frontend/plugins.css )
Rails.application.config.assets.precompile += %w( frontend/main.css )
Rails.application.config.assets.precompile += %w( frontend/themes.css )
Rails.application.config.assets.precompile += %w( frontend/plugins.js )
Rails.application.config.assets.precompile += %w( frontend/app.js )

#Backend
Rails.application.config.assets.precompile += %w( backend/plugins.css )
Rails.application.config.assets.precompile += %w( backend/main.css )
Rails.application.config.assets.precompile += %w( backend/themes.css )
Rails.application.config.assets.precompile += %w( backend/app.css )
Rails.application.config.assets.precompile += %w( backend/plugins.js )
Rails.application.config.assets.precompile += %w( backend/app.js )

#Login
Rails.application.config.assets.precompile += %w( backend/pages/login.js )