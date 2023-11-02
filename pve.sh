#!/bin/bash

Version=v1.1.0

Backup_path="/etc/apt/backup"
Script_Path="/tmp/pve/script"

Sources_list="/etc/apt/sources.list"
APLInfo_pm="/usr/share/perl5/PVE/APLInfo.pm"
Ceph_list="/etc/apt/sources.list.d/ceph.list"
Pve_no_subscription_list="/etc/apt/sources.list.d/pve-no-subscription.list"
Pve_enterprise_list="/etc/apt/sources.list.d/pve-enterprise.list"
Proxmoxlib_js="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

URL_Download_Version="https://raw.githubusercontent.com/roacn/pve/main/lxc/version"
URL_Download_Script="https://raw.githubusercontent.com/roacn/pve/main/pve.sh"

function __error_msg() {
    echo -e "\033[31m[ERROR]\033[0m $*"
}
function __success_msg() {
    echo -e "\033[32m[SUCCESS]\033[0m $*"
}
function __warning_msg() {
    echo -e "\033[33m[WARNING]\033[0m $*"
}
function __info_msg() {
    echo -e "\033[36m[INFO]\033[0m $*"
}
function __red_color() {
    echo -e "\033[31m$*\033[0m"
}
function __green_color() {
    echo -e "\033[32m$*\033[0m"
}
function __yellow_color() {
    echo -e "\033[33m$*\033[0m"
}
function __blue_color() {
    echo -e "\033[34m$*\033[0m"
}
function __magenta_color() {
    echo -e "\033[35m$*\033[0m"
}
function __cyan_color() {
    echo -e "\033[36m$*\033[0m"
}
function __white_color() {
    echo -e "\033[37m$*\033[0m"
}

function pause(){
    echo
    read -n 1 -p "Press any key to continue..." input
    if [[ -n ${input} ]]; then
        echo -e "\b\n"
    fi
}

#--------------pve_optimization-start----------------
# Debian源
set_apt_sources() {
	echo
	__yellow_color "开始更换debian源..."
	[[ "${VERSION_CODENAME}" == "bookworm" ]] && nonfree="non-free non-free-firmware" || nonfree="non-free"
	[[ `cat ${Sources_list} 2>/dev/null | grep -c "proxmox.com"` -ge 1 ]] && cp -rf ${Sources_list} ${Backup_path}/sources.list.bak
	echo "请选择您需要的Debian系统源"
	echo "1. 清华大学镜像站"
	echo "2. 中科大镜像站"
	echo "3. 上海交大镜像站"
	echo "4. 阿里云镜像站"
	echo "5. 腾讯云镜像站"
	echo "6. 网易镜像站"
	echo "7. 华为镜像站"
	input="请输入选择[默认1]"
	while :; do
	read -t 30 -p "${input}： " aptsource || echo
	aptsource=${aptsource:-1}
	case $aptsource in
	1)
	cat > ${Sources_list} <<-EOF
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 清华大学安全更新镜像源
		deb https://mirrors.tuna.tsinghua.edu.cn/debian-security ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;
	2)
	cat > ${Sources_list} <<-EOF
		deb https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 中科大安全更新镜像源
		deb https://mirrors.ustc.edu.cn/debian-security ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirrors.ustc.edu.cn/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirrors.ustc.edu.cn/debian-security ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;  
	3)
	cat > ${Sources_list} <<-EOF
		deb https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 上海交大安全更新镜像源
		deb https://mirror.sjtu.edu.cn/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirror.sjtu.edu.cn/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirror.sjtu.edu.cn/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;
	4)
	cat > ${Sources_list} <<-EOF
		deb https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 阿里云安全更新镜像源
		deb https://mirrors.aliyun.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirrors.aliyun.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirrors.aliyun.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;
	5)
	cat > ${Sources_list} <<-EOF
		deb https://mirrors.tencent.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 腾讯安全更新镜像源
		deb https://mirrors.tencent.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirrors.tencent.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirrors.tencent.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirrors.tencent.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;
	6)
	cat > ${Sources_list} <<-EOF
		deb https://mirrors.163.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirrors.163.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirrors.163.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirrors.163.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirrors.163.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 网易安全更新镜像源
		deb https://mirrors.163.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirrors.163.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirrors.163.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirrors.163.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirrors.163.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirrors.163.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirrors.163.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;
	7)
	cat > ${Sources_list} <<-EOF
		deb https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		deb https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		deb https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		# 华为云安全更新镜像源
		deb https://mirrors.huaweicloud.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
		# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
		#deb-src https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME} main contrib ${nonfree}
		#deb-src https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-backports main contrib ${nonfree}
		#deb-src https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-backports-sloppy main contrib ${nonfree}
		#deb-src https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-proposed-updates main contrib ${nonfree}
		#deb-src https://mirrors.huaweicloud.com/debian/ ${VERSION_CODENAME}-updates main contrib ${nonfree}
		#deb-src https://mirrors.huaweicloud.com/debian-security/ ${VERSION_CODENAME}-security main contrib ${nonfree}
	EOF
	break
	;;
	*)
	__error_msg "请输入正确数字"
	;;
	esac
	done
	__success_msg "已完成！"
}

# proxmox源
# 关于存储库错误
# Proxmox VE 无法识别镜像的 Proxmox 源，因此使用镜像源会被识别为未添加 Proxmox 源，导致出现 “没有启用 Proxmox VE 存储库，你没有得到任何更新！” 的错误。
# 如果希望修复本问题，可以将源改为 http://download.proxmox.com/debian/pve ，存储库状态会从错误变恢复为警告。
set_pve_no_subscription(){
	echo
	__yellow_color "开始更换proxmox源..."
	[[ `cat ${Pve_no_subscription_list} 2>/dev/null | grep -c "proxmox.com"` -ge 1 ]] && cp -rf ${Pve_no_subscription_list} ${Backup_path}/pve-no-subscription.list.bak
	
	echo "请选择您需要的Proxmox软件源"
	echo "1. 清华大学镜像站"
	echo "2. 中科大镜像站"
	input="请输入选择[默认1]"
	while :; do
		read -t 30 -p "${input}： " pvesource || echo
		pvesource=${pvesource:-1}
		case $pvesource in
		1)
			echo "deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve ${VERSION_CODENAME} pve-no-subscription" > ${Pve_no_subscription_list}
			echo "# deb http://download.proxmox.com/debian/pve ${VERSION_CODENAME} pve-no-subscription" >> ${Pve_no_subscription_list}
			break
		;;
		2)
			echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/pve ${VERSION_CODENAME} pve-no-subscription" > ${Pve_no_subscription_list}
			echo "# deb http://download.proxmox.com/debian/pve ${VERSION_CODENAME} pve-no-subscription" >> ${Pve_no_subscription_list}
			break
		;;
		*)
			__error_msg "请输入正确数字"
		;;
		esac
	done
	
	__success_msg "已完成！"
}

# CT模板源,针对 /usr/share/perl5/PVE/APLInfo.pm 文件的修改，重启后生效
set_ct_sources() {
	echo
	__yellow_color "开始更换CT模板源..."
	[[ `cat ${APLInfo_pm} 2>/dev/null | grep -c "http://download.proxmox.com"` -ge 1 ]] && cp -rf ${APLInfo_pm} ${Backup_path}/APLInfo.pm.bak
	echo "请选择您需要的CT模板国内源"
	echo "1. 清华大学镜像站"
	echo "2. 中科大镜像站"
	input="请输入选择[默认1]"
	while :; do
		read -t 30 -p "${input}： " ctsource || echo
		ctsource=${ctsource:-1}
		case $ctsource in
		1)
			sed -i 's|\(url => "\).*\(/images\)|\1https://mirrors.tuna.tsinghua.edu.cn/proxmox\2|g' ${APLInfo_pm}
			break
		;;
		2)
			sed -i 's|\(url => "\).*\(/images\)|\1https://mirrors.ustc.edu.cn/proxmox\2|g' ${APLInfo_pm}
			break
		;;
		*)
			__error_msg "请输入正确编码！"
		;;
		esac
	done
	__success_msg "已完成！"
}

# ceph源
set_ceph() {
	echo
	__yellow_color "开始更换ceph源..."
	[[ `cat ${Ceph_list} 2>/dev/null | grep -c "proxmox.com"` -ge 1 ]] && cp -rf ${Ceph_list} ${Backup_path}/ceph.list.bak
	local ceph_codename=`ceph -v | grep ceph | awk '{print $(NF-1)}'`
	echo "deb https://mirrors.ustc.edu.cn/proxmox/debian/ceph-$ceph_codename ${VERSION_CODENAME} no-subscription" > ${Ceph_list}
	__success_msg "已完成！"
}

# 关闭企业源
set_pve_enterprise(){
	echo
	__yellow_color "开始关闭企业源..."
	if [[ -f ${Pve_enterprise_list} ]];then
		[[ `cat ${Pve_enterprise_list} | grep -c "proxmox.com"` -ge 1 ]] && cp -rf ${Pve_enterprise_list} ${Backup_path}/pve-enterprise.list.bak
		#rm -rf ${Pve_enterprise_list}
		sed -i 's|^deb https://enterprise.proxmox.com|# deb https://enterprise.proxmox.com|g' ${Pve_enterprise_list}
		__success_msg "已完成！"
	#else
	#	__warning_msg "${Pve_enterprise_list}文件不存在，略过..."
	fi
}

# 移除无效订阅
set_novalidsub(){
	echo
	__yellow_color "开始移除“Proxmox VE 无有效订阅”提示..."
	sed -Ezi.bak "s|(\s+)(Ext.Msg.show\(\{\s+title: gettext\('No valid subscription)|\1void\(\{ \/\/\2|g" ${Proxmoxlib_js}
	__success_msg "已完成！"
}

set_pve_gpg(){
	echo
	__yellow_color "开始下载GPG密钥..."
	[[ -f /etc/apt/trusted.gpg.d/proxmox-release-${VERSION_CODENAME}.gpg ]] && mv -f /etc/apt/trusted.gpg.d/proxmox-release-${VERSION_CODENAME}.gpg ${Backup_path}/proxmox-release-${VERSION_CODENAME}.gpg.bak
	wget -q --timeout=5 --tries=2 http://mirrors.ustc.edu.cn/proxmox/debian/proxmox-release-${VERSION_CODENAME}.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-${VERSION_CODENAME}.gpg
	if [[ $? -ne 0 ]];then
		__error_msg "GPG密钥下载失败，请检查网络再尝试!"
	else
		__success_msg "已完成！"	
	fi
}

pve_optimization(){
	source /etc/os-release
	clear
	__yellow_color "温馨提示：PVE原配置文件放入${Backup_path}文件夹"
	[[ ! -d ${Backup_path} ]] && mkdir -p ${Backup_path}
	set_apt_sources
	set_ct_sources
	set_pve_no_subscription
	set_ceph
	set_pve_enterprise
	set_novalidsub
	set_pve_gpg
	echo
	__yellow_color "重新加载服务配置文件、重启web控制台..."
	systemctl daemon-reload && systemctl restart pveproxy.service && __success_msg "已完成！"
	#echo
	#__yellow_color "更新源、安装常用软件和升级..."
	#__yellow_color "如需对PVE进行升级，请使用apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y"
	pause
}
#--------------pve_optimization-end----------------


#--------------hw_passth-start----------------
# 开启硬件直通
enable_pass(){
	echo
	__yellow_color "开启硬件直通..."
	if [ `dmesg | grep -e DMAR -e IOMMU|wc -l` = 0 ];then
		__error_msg "您的硬件不支持直通！"
	fi
	if [ `cat /proc/cpuinfo|grep Intel|wc -l` = 0 ];then
		iommu="amd_iommu=on"
	else
		iommu="intel_iommu=on"
	fi
	if [ `grep $iommu /etc/default/grub|wc -l` = 0 ];then
		sed -i 's|quiet|quiet '$iommu'|' /etc/default/grub
		update-grub
		if [ `grep "vfio" /etc/modules|wc -l` = 0 ];then
			cat <<-EOF >> /etc/modules
				vfio
				vfio_iommu_type1
				vfio_pci
				vfio_virqfd
			EOF
		fi
		__success_msg "开启设置后需要重启系统，请稍后重启。"
	else
		__warning_msg "您已经配置过!"
	fi

}

# 关闭硬件直通
disable_pass(){
	echo
	__yellow_color "关闭硬件直通..."
	if [ `dmesg | grep -e DMAR -e IOMMU|wc -l` = 0 ];then
		__error_msg "您的硬件不支持直通！"
	fi
	if [ `cat /proc/cpuinfo|grep Intel|wc -l` = 0 ];then
		iommu="amd_iommu=on"
	else
		iommu="intel_iommu=on"
	fi
	if [ `grep $iommu /etc/default/grub|wc -l` = 0 ];then
		__warning_msg "您还没有配置过该项"
	else
		{
			sed -i 's/ '$iommu'//g' /etc/default/grub
			sed -i '/vfio/d' /etc/modules
			sleep 1
		}
		__info_msg "关闭设置后需要重启系统，请稍后重启。"
		sleep 1
		update-grub
	fi
}

# 硬件直通菜单
hw_passth(){
	while :; do
		clear
		cat <<-EOF
`__green_color "	      配置硬件直通"`
┌────────────────────────────────────────────────────┐
    1. 开启硬件直通
    2. 关闭硬件直通
  ──────────────────────────────────────────────────
    0. 返回
└────────────────────────────────────────────────────┘
EOF
		echo -ne "请选择: [ ]\b\b"
		read -t 60 hwmenuid
		hwmenuid=${hwmenuid:-0}
		case "${hwmenuid}" in
		1)
			enable_pass
			pause
			break
		;;
		2)
			disable_pass
			pause
			break
		;;
		0)
			break
		;;
		*)
		;;
		esac
	done
}
#--------------hw_passth-end----------------


#--------------cpu_freq-start----------------
# CPU模式
cpu_governor(){
	governors=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`
	while :; do
		clear
		cat <<EOF
`__green_color "	      设置CPU模式"`
┌────────────────────────────────────────────────────┐
    1. ondemand		[默认]
    2. conservative
    3. userspace
    4. powersave
    5. performance
    6. schedutil
└────────────────────────────────────────────────────┘
EOF
		echo -ne "请选择: [ ]\b\b"
		read -t 10 governorid
		governorid=${governorid:-1}
		case "${governorid}" in
		1)
			GOVERNOR="ondemand"
		;;
		2)
			GOVERNOR="conservative"
		;;
		3)
			GOVERNOR="userspace"
		;;	
		4)
			GOVERNOR="powersave"
		;;
		5)
			GOVERNOR="performance"
		;;
		6)
			GOVERNOR="schedutil"
		;;
		*)
			GOVERNOR=""
		;;
		esac
		if [[ ${GOVERNOR} != "" ]]; then
			if [[ -n `echo "${governors}" | grep -o "${GOVERNOR}"` ]]; then
				__info_msg "您选择的CPU模式：${GOVERNOR}"
				break
			else
				__error_msg "您的CPU不支持该模式！"
				sleep 2
			fi
		fi
	done
}

# CPU最大频率
cpu_maxfreq(){
	echo
	info=`cpufreq-info | grep "hardware limits" | uniq | awk -F: '{print $2}' | sed 's/ //g'`
	__green_color "当前CPU默认频率范围：${info}"
	echo "示例：以J4125为例，最大频率2.7GHz，输入2700000"
	while :; do
		read -t 30 -p "请输入CPU最大频率[单位HZ]：" maxfreq || echo
		maxfreq=${maxfreq:-2700000}
		nmax=`echo ${maxfreq} | sed 's/[0-9]//g'`
		if [[ ! -z $nmax ]]; then
			__error_msg "输入错误，请重新输入！"
		elif [[ ${maxfreq} -lt 100000 ]] || [[ ${maxfreq} -gt 9000000 ]] || [[ ${maxfreq} == "" ]]; then
			__error_msg "貌似输入值的范围不正确，请重新输入！"
		else
			MAX_SPEED=${maxfreq}
			__info_msg "CPU最大频率设置为：${MAX_SPEED} HZ"
			break
		fi
	done
}

# CPU最小频率
cpu_minfreq(){
	echo
	info=`cpufreq-info | grep "hardware limits" | uniq | awk -F: '{print $2}' | sed 's/ //g'`
	__green_color "当前CPU默认频率范围：${info}"
	echo "示例：以J4125为例，最小频率800MHz，输入800000"
	while :; do
		read -t 30 -p "请输入CPU最小频率[单位HZ]：" minfreq || echo
		minfreq=${minfreq:-800000}
		nmin=`echo ${minfreq} | sed 's/[0-9]//g'`
		if [[ ! -z $nmin ]]; then
			__error_msg "输入错误，请重新输入！"
		elif [[ ${minfreq} -lt 100000 ]] || [[ ${minfreq} -gt ${MAX_SPEED} ]] || [[ ${minfreq} == "" ]]; then
			__error_msg "貌似输入值的范围不正确，请重新输入！"
		else
			MIN_SPEED=${minfreq}
			__info_msg "CPU最小频率设置为：${MIN_SPEED} HZ"
			break
		fi
	done
}

# 设置CPU频率
do_cpufreq(){
	echo
	__yellow_color "配置CPU模式"
	sleep 1
	install_tools
	if [ `grep "intel_pstate=disable" /etc/default/grub|wc -l` = 0 ];then
		sed -i 's|quiet|quiet intel_pstate=disable|' /etc/default/grub
		update-grub
	fi
	cpu_governor
	cpu_maxfreq
	cpu_minfreq
	cat > /etc/default/cpufrequtils <<-EOF
ENABLE="true"
GOVERNOR="${GOVERNOR}"
MAX_SPEED="${MAX_SPEED}"
MIN_SPEED="${MIN_SPEED}"
EOF
	echo
	__success_msg "已安装好，请稍后重启。"
}

# 还原CPU模式
undo_cpufreq(){
	echo
	__yellow_color "还原CPU模式"
	cat > /etc/default/cpufrequtils <<-EOF
ENABLE="true"
GOVERNOR="ondemand"
EOF
	systemctl restart cpufrequtils
	while :; do
		read -t 30 -p "y/Y继续；n/N返回：" rmgoon || echo
		rmgoon=${rmgoon:-y}
		case ${rmgoon} in
		y|Y)
			apt -y remove cpufrequtils > /dev/null 2>&1 && \
			sed -i 's/ intel_pstate=disable//g' /etc/default/grub && \
			rm -rf /etc/default/cpufrequtils
			__success_msg "已还原，请稍后重启。"
			break
		;;
		n|N)
			break
		;;
		*)
		;;
		esac
	done
}

# CPU模式菜单
cpu_freq(){
	clear
	cat <<-EOF
`__green_color "	      cpufrequtils工具"`
┌────────────────────────────────────────────────────┐
    1. 安装配置
    2. 还原配置
  ──────────────────────────────────────────────────
    0. 返回
└────────────────────────────────────────────────────┘
EOF
	echo -ne "请选择: [ ]\b\b"
	read -t 60 cpumenuid
	cpumenuid=${cpumenuid:-0}
	case "${cpumenuid}" in
	1)
		if [ `grep "intel_pstate=disable" /etc/default/grub|wc -l` = 0 ];then
			do_cpufreq
		else
			__warning_msg "查询到/etc/default/grub存在intel_pstate=disable配置，可能已经配置过。"
			while :; do
				read -t 10 -p "y/Y继续；n/N返回：" chgoon || echo
				chgoon=${chgoon:-y}
				case ${chgoon} in
				y|Y)
					do_cpufreq
					break
				;;
				n|N)
					break
				;;
				*)
				;;
				esac
			done
		fi
		pause
	;;
	2)
		undo_cpufreq
		pause
	;;
	0)
		return
	;;
	*)
		cpu_freq		
	esac
}
#--------------cpu_freq-end----------------


# 安装工具
install_tools(){
	pve_pkgs="cpufrequtils"
	for i in ${pve_pkgs}; do
		if [[ $(apt list --installed 2>/dev/null | grep -o "^${i}\/" | wc -l) -ge 1 ]]; then
			__info_msg "${i} 已安装"
			sleep 3
		else
			clear
			__warning_msg "${i} 未安装"
			__green_color "开始安装${i} ..."
			apt install -y ${i} > /dev/null 2>&1
		fi
	done
}

function network_check() {
	Google_check="$(curl -I -s --connect-timeout 3 google.com -w %{http_code} | tail -n1)"
}

function script_version() {
	[[ ! -d ${Script_Path} ]] && mkdir -p ${Script_Path} || rm -rf ${Script_Path}/*
	[[ -z ${Google_check} ]] && network_check
	if [[ "${Google_check}" == "301" ]];then
		wget -q --timeout=5 --tries=2 ${URL_Download_Version} -O ${Script_Path}/version
		if [[ $? -ne 0 ]];then
			curl -fsSL ${URL_Download_Version} -o ${Script_Path}/version
			if [[ $? -ne 0 ]]; then
				return
			fi
		fi
	else
		wget -q --timeout=5 --tries=2 https://ghproxy.com/${URL_Download_Version} -O ${Script_Path}/version
		if [[ $? -ne 0 ]]; then
			curl -fsSL https://ghproxy.com/${URL_Download_Version} -o ${Script_Path}/version
			if [[ $? -ne 0 ]]; then
				return
			fi
		fi
	fi

	chmod +x ${Script_Path}/version
}

function script_download() {
	if [[ "${Google_check}" == "301" ]];then
		curl -fsSL ${URL_Download_Script} -o ${Script_Path}/pve
		if [[ $? -ne 0 ]];then
			wget -q --timeout=5 --tries=2 ${URL_Download_Script} -O ${Script_Path}/pve
			if [[ $? -ne 0 ]];then
				__error_msg "脚本更新失败，请检查网络，重试！"
				return
			fi
		fi
	else
		curl -fsSL https://ghproxy.com/${URL_Download_Script} -o ${Script_Path}/pve
		if [[ $? -ne 0 ]]; then
			wget -q --timeout=5 --tries=2 https://ghproxy.com/${URL_Download_Script} -O ${Script_Path}/pve
			if [[ $? -ne 0 ]];then
				__error_msg "脚本更新失败，请检查网络，重试！"
				return
			fi
		fi
	fi

	if [[ -s ${Script_Path}/pve ]];then
		cp -f ${Script_Path}/pve /usr/bin/pve && chmod +x /usr/bin/pve
		__success_msg "脚本更新成功，请退出重新运行！"
	fi
}

function script_udpate() {
	script_version
	if [[ -s ${Script_Path}/version ]]; then
		source ${Script_Path}/version 2 > /dev/null
	fi

	if [[ -z ${LatestVersion_PVE} ]]; then
		__error_msg "获取版本信息失败，或网络不稳定，请稍后再试！"
		return
	fi

	while :; do
		clear
cat <<-EOF
`__green_color "	      脚本版本信息"`
┌────────────────────────────────────────────────────┐
    最新版本: ${LatestVersion_PVE}
    当前版本: ${Version}
└────────────────────────────────────────────────────┘
EOF
		echo -ne "y/Y升级；n/N返回："
		read -t 60 enable_script_udpate
		enable_script_udpate=${enable_script_udpate:-n}
		case ${enable_script_udpate} in
		y|Y)
			script_download
			pause
			break
		;;
		n|N)
			break
		;;
		*)
			__error_msg "输入错误，请重新输入！"
		;;
		esac
	done
}


while true
do
	clear
	cat <<-EOF
`__green_color "	      PVE优化脚本 ${Version}"`
┌────────────────────────────────────────────────────┐
    1. 一键优化PVE(换源、去订阅等)
    2. 配置PCI硬件直通
    3. CPU睿频模式
    4. CPU、主板、硬盘温度显示
  ──────────────────────────────────────────────────
    5. 升级脚本
    0. 退出
└────────────────────────────────────────────────────┘
EOF
	echo -ne "请选择: [ ]\b\b"
	read -t 60 menuid
	menuid=${menuid:-0}
	case ${menuid} in
	1)
		pve_optimization
	;;
	2)
		hw_passth
	;;
	3)
		cpu_freq
	;;
	4)
		echo "TODO."
		pause
	;;
	5)
		script_udpate
	;;
	0)
		clear
		exit 0
	;;
	*)
	;;
	esac
done
