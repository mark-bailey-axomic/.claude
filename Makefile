.PHONY: restore-plugins

restore-plugins:
	@echo "Restoring plugins..."
	bash ./scripts/shell/restore-plugins.sh
	@echo "Plugins restored successfully!"
	