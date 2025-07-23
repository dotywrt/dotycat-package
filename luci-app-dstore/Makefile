include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-dstore
PKG_VERSION:=1.0
PKG_RELEASE:=7

PKG_MAINTAINER:=dotycat <support@dotycat.com>
PKG_LICENSE:=GPL-3.0

LUCI_TITLE:=DStore App Manager
LUCI_DESCRIPTION:=This LuCI app provides a web interface for managing apps from multiple JSON sources.

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=$(LUCI_TITLE)
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	$(LUCI_DESCRIPTION)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
