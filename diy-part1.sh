#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
cd ..
#######################################下载coolsnowwolf lede源码######################################
git clone https://github.com/coolsnowwolf/lede
#复制lean到openwrt/package
cp -r ./lede/package/lean ./openwrt/package
#复制ucl到openwrt/tools##vssr必备插件
#cp -r ./lede/tools/ucl ./openwrt/tools
#复制upx到openwrt/tools##vssr必备插件
#cp -r ./lede/tools/upx ./openwrt/tools
#删除lede源码节省空间
rm -rf ./lede

####################vssr必备修改，https://github.com/fw876/helloworld####################################
svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/ucl tools/ucl
svn checkout https://github.com/coolsnowwolf/lede/trunk/tools/upx tools/upx

sed -i 'N;24a\tools-y += ucl upx' tools/Makefile
sed -i 'N;40a\$(curdir)/upx/compile := $(curdir)/ucl/compile' tools/Makefile

mkdir -p package/helloworld
for i in "dns2socks" "microsocks" "ipt2socks" "pdnsd-alt" "redsocks2"; do \
  svn checkout "https://github.com/immortalwrt/packages/trunk/net/$i" "package/helloworld/$i"; \
done


################################目的是提取vssr需要的libmaxminddb######################################
#下载openwrt/package 21.02源码
#git clone -b openwrt-21.02 https://github.com/openwrt/packages
#复制libmaxminddb到openwrt/package/libs
#cp -r ./packages/libs/libmaxminddb ./openwrt/package/libs
#复制ruby到openwrt
#cp -r ./packages/lang/ruby ./openwrt
#删除packages源码节省空间
#rm -rf ./packages

cd openwrt

##########################################下载openclash######################################
#git clone https://github.com/vernesong/OpenClash.git
#Clone 项目
#mkdir package/luci-app-openclash
#cd package/luci-app-openclash
#git init
#git remote add -f origin https://github.com/vernesong/OpenClash.git
#git config core.sparsecheckout true
#echo "luci-app-openclash" >> .git/info/sparse-checkout
#git pull --depth 1 origin master
#git branch --set-upstream-to=origin/master master
# 编译 po2lmo (如果有po2lmo可跳过)
#pushd luci-app-openclash/tools/po2lmo
#make && sudo make install
#popd

cd package/lean/  
git clone https://github.com/jerrykuku/lua-maxminddb.git  #git lua-maxminddb 依赖
git clone https://github.com/jerrykuku/luci-app-vssr.git  
ls
cd ..
cd ..

#注释掉include/target.mk第16行
sed -i '16s/^/#/' include/target.mk
#include/target.mk第16行后面添加一行
sed -i '16a \DEFAULT_PACKAGES:=base-files libc libgcc busybox dropbear mtd uci opkg netifd fstools uclient-fetch logd default-settings luci-app-vlmcsd' include/target.mk
#注释掉include/target.mk第21行
sed -i '21s/^/#/' include/target.mk
#include/target.mk第21行后面添加一行
sed -i '21a \DEFAULT_PACKAGES.router:=dnsmasq-full iptables ip6tables firewall odhcpd-ipv6only odhcp6c kmod-ipt-offload' include/target.mk

#修改package/kernel/linux/files/sysctl-nf-conntrack.conf连接数16384为65536
sed -i 's/16384/65536/' package/kernel/linux/files/sysctl-nf-conntrack.conf

# Modify default IP 修改原始IP 【原：lan) ipad=${ipaddr:-"192.168.1.1"}】
sed -i '103s/192.168.1.1/192.168.168.1/g' package/base-files/files/bin/config_generate

#替换tiny-tp-link.mk文件第471行字符
sed -i '471s/4mlzma/16mlzma/g' target/linux/ar71xx/image/tiny-tp-link.mk
cat target/linux/ar71xx/image/tiny-tp-link.mk

#删除02_network文件第142行
sed -i '142d' target/linux/ar71xx/base-files/etc/board.d/02_network

#在153行末尾新增tl-wr802n-v1)设定，新增WAN口LAN口
#sed -i 'N;153a\\ttl-wr802n-v1)\n\t\tucidef_set_interface_wan \"eth0\"\n\t\tucidef_set_interface_lan \"eth1\"\n\t\t\;\;' target/linux/ar71xx/base-files/etc/board.d/02_network #不能用
sed -i '153a \\ttl-wr802n-v1)\n\t\tucidef_set_interface_wan \"eth0\"\n\t\tucidef_set_interface_lan \"eth1\"\n\t\t\;\;' target/linux/ar71xx/base-files/etc/board.d/02_network
cat target/linux/ar71xx/base-files/etc/board.d/02_network
#在88行末尾新增，设置WAN信息，默认网口为WAN口
sed -i '88a \\tath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_MII\;\n\tath79_eth1_data.duplex = DUPLEX_FULL\;\n\tath79_eth1_data.speed = SPEED_100\;\n\tath79_eth1_data.phy_mask = BIT(4)\;\n\tath79_init_mac(ath79_eth1_data.mac_addr, mac, 2)\;\n\tath79_register_eth(1)\;\n' target/linux/ar71xx/files/arch/mips/ath79/mach-tl-wr802n.c
cat target/linux/ar71xx/files/arch/mips/ath79/mach-tl-wr802n.c
#默认开启wifi
sed -i '116s/1/0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
cat package/kernel/mac80211/files/lib/wifi/mac80211.sh
 
 
 ######################修改feeds.conf.default文件###########################
#sed -i '$a src-git kenzsp https\:\/\/github.com\/kenzok8\/small-package' feeds.conf.default
#sed -i '$a src-git small https\:\/\/github.com\/kenzok8\/small' feeds.conf.default
#sed -i '$a src-git kenzop https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git helloworld https://github.com/fw876/helloworld' feeds.conf.default
sed -i '$a src-git passwall https://github.com/xiaorouji/openwrt-passwall' feeds.conf.default
cat feeds.conf.default












#sed -i 's/skip/b99ef18516b705b3e73b15a9d5ddc99add359299b52639fe3c81dd761591d9d9/' /package/feeds/kenzo/lua-maxminddb/Makefile
#cat /package/feeds/kenzo/lua-maxminddb/Makefile

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default


