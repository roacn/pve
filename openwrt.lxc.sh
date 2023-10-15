#!/bin/bash
# URL: https://github.com/roacn/build-actions
# Description: AutoUpdate for Openwrt
# Author: Ss.
# Please use the PVE command line to run the shell script.

Version=v2.0.0

Openwrt_Path="/tmp/openwrt"
Firmware_Path="/tmp/openwrt/firmware"
Script_Path="/tmp/openwrt/script"
Creatlxc_Path="/tmp/openwrt/creatlxc"
Settings_File="/etc/openwrt.conf"
Upgrade_file="/etc/openwrt.upgrade"
Backup_Path="/root/openwrt"

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

# pause
function pause(){
    read -n 1 -p "Press any key to continue..." input
    if [[ -n ${input} ]]; then
        echo -e "\b\n"
    fi
}

# 初始化设置
function init_settings() {
    [[ ! -d ${Openwrt_Path} ]] && mkdir -p ${Openwrt_Path}
    
    if [[ ! -f ${Settings_File} ]]; then
cat > ${Settings_File} <<-EOF
Repository="roacn/build-actions"
Tag_name="AutoUpdate-x86-lxc"
Github_api="zzz_api"
Priority="default"
EOF
        chmod +x ${Settings_File}
        __warning_msg "首次运行，使用默认设置，如需修改，请到主菜单'设置'选项."
        pause
    fi
}

# 加载配置
function load_settings() {
    source ${Settings_File}
    Github_api_url="https://api.github.com/repos/${Repository}/releases/tags/${Tag_name}"
    URL_Download_Release="https://github.com/${Repository}/releases/download/${Tag_name}"
    URL_Download_Version="https://raw.githubusercontent.com/roacn/pve/main/lxc/version"
    URL_Download_Script="https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh"
}

# 修改配置
function settings_modify() {
    while :; do
    source ${Settings_File}
    clear
cat <<-EOF
`__red_color "     OpenWrt自动安装升级脚本  ${Version}"`
┌────────────────────────────────────────────┐
      仓库地址:	${Repository}
      TAG名称:	${Tag_name}
      API文件:	${Github_api}
      固件优选:	${Priority}
└────────────────────────────────────────────┘
EOF
        echo -ne "修改或返回[y/Y或n/N，默认n]:"
        read -t 30 enable_settings_modify
        enable_settings_modify=${enable_settings_modify:-n}
        case ${enable_settings_modify} in
        y|Y)
            set_repository
            set_tag
            set_api
            set_priority
cat > ${Settings_File} <<-EOF
Repository="${Repository}"
Tag_name="${Tag_name}"
Github_api="${Github_api}"
Priority="${Priority}"
EOF
            break
        ;;
        n|N)
            menu
            break
        ;;
        *)
            __error_msg "输入错误，请重新输入！"
        ;;
        esac
    done
}

# 设置仓库地址
function set_repository() {
    echo
    read -t 30 -p "请输入仓库地址[github用户名/仓库名]：" input_repo || echo
    input_repo=${input_repo:-"roacn/build-actions"}
    Repository="${input_repo}"
}

# 设置tag
function set_tag() {
    echo
    read -t 30 -p "请输入tag名称[默认AutoUpdate-x86-lxc]：" input_tag || echo
    input_tag=${input_tag:-"AutoUpdate-x86-lxc"}
    Tag_name="${input_tag}"
}

# 设置api
function set_api() {
    echo
    read -t 30 -p "请输入api文件名称[默认zzz_api]：" input_api || echo
    input_api=${input_api:-"zzz_api"}
    Github_api="${input_api}"
}

# 设置固件优选
function set_priority() {
    echo
    echo "请输入优选哪种格式固件:"
    echo "0. .tar.gz或.img.gz格式固件；"
    echo "1. 只选.tar.gz格式固件；"
    echo "2. 只选.img.gz格式固件；"
    while :; do
        read -t 30 -p "请输入数字[默认0]：" input_priority || echo
        input_priority=${input_priority:-0}
        case ${input_priority} in
        0)
            Priority="default"
            break
        ;;
        1)
            Priority=".tar.gz"
            break
        ;;
        2)
            Priority=".img.gz"
            break
        ;;
        *)
            __error_msg "输入错误，请重新输入！"
        ;;
        esac
    done
}

# 更新OpenWrt CT模板I
function release_choose(){
    echo
    local firmware_list_multi="${Firmware_Path}/firmware_list_multi"
    local firmware_list_tar="${Firmware_Path}/firmware_list_tar"
    local firmware_list_img="${Firmware_Path}/firmware_list_img"
    local firmware_multi=$(grep -E "\"name\"" ${Firmware_Path}/${Github_api} | grep -i -Eo ".*rootfs.*\.gz" | sed "s/ //g" | sed "s/\"//g" | awk -F ':' '{print $2;}' | sort -r)
    local firmware_tar=$(echo "${firmware_multi}" | grep -i -E ".*\.tar.*\.gz")
    local firmware_img=$(echo "${firmware_multi}" | grep -i -E ".*\.img.*\.gz")
    echo "${firmware_multi}" > ${firmware_list_multi}
    echo "${firmware_tar}" > ${firmware_list_tar}
    echo "${firmware_img}" > ${firmware_list_img}
    
    if [[ "${Priority}" == ".tar.gz" ]]; then
        firmware_list=${firmware_list_tar}
    elif [[ "${Priority}" == ".img.gz" ]]; then
        firmware_list=${firmware_list_tar}
    else
        firmware_list=${firmware_list_multi}
    fi
    
    echo "Github云端固件:"
    nl "${firmware_list}"
    if [[ -z ${firmware_list} ]]; then
        __error_msg "当前云端固件列表为空，请检查！"
        exit 1
    fi
    
    while :; do
        read -t 30 -p "请输入要下载固件对应序号n[默认n=1]：" input_release
        input_release=${input_release:-1}
        check_input_release=`echo ${input_release} | sed 's/[0-9]//g'`
        if [[ -n $check_input_release ]]; then
            __error_msg "输入错误，请输入数字！"
        elif [[ ${input_release} -eq 0 ]] || [[ ${input_release} -gt $(cat "${firmware_list}" | wc -l) ]]; then
            __error_msg "超出范围，请重新输入！"
        else
            Firmware_to_download=$(cat "${firmware_list}" | head -n ${input_release} | tail -n 1)
            __green_color " [已选] ${Firmware_to_download}"
            break
        fi
    done
}

# 更新OpenWrt CT模板II
function update_CT_Templates(){
    [[ ! -d ${Firmware_Path} ]] && mkdir -p ${Firmware_Path} || rm -rf ${Firmware_Path}/*
    echo
    __yellow_color "下载OpenWrt固件"
    
    ping 223.5.5.5 -c 1 -W 2 > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        __error_msg "网络连接错误!"
        exit 1
    fi
    
    echo
    __green_color "获取固件API信息..."
    rm -rf ${Firmware_Path}/${Github_api}
    if [[ "${Google_check}" == "301" ]];then
        wget -q --timeout=5 --tries=2 --show-progress ${Github_api_url} -O ${Firmware_Path}/${Github_api}
        if [[ $? -ne 0 ]];then
            __error_msg "直连github获取固件API信息失败，请检测网络，或网址是否正确！"
            exit 1
        fi
    else
        wget -q --timeout=5 --tries=2 --show-progress "https://ghproxy.com/${URL_Download_Release}/${Github_api}" -O ${Firmware_Path}/${Github_api}
        if [[ $? -ne 0 ]]; then
            curl -fsSL "https://ghproxy.com/${URL_Download_Release}/${Github_api}" -O ${Firmware_Path}/${Github_api}
            if [[ $? -ne 0 ]];then
                __error_msg "通过代理获取固件API信息失败，请检测网络，或网址是否正确！"
                exit 1
            fi
        fi
    fi
    __success_msg "获取固件API信息成功！"
    
    # 选择固件
    release_choose
    
    # 下载固件
    local firmware_ext=${Firmware_to_download:0-7:7}
    local firmware_downloaded="openwrt.rootfs${firmware_ext}"

    echo
    __green_color "开始下载固件..."
    if [[ -n ${Firmware_to_download} ]];then
        if [[ "${Google_check}" == "301" ]];then
            wget -q --timeout=5 --tries=2 --show-progress ${URL_Download_Release}/${Firmware_to_download} -O ${Firmware_Path}/${firmware_downloaded}
            if [[ $? -ne 0 ]];then
                __error_msg "获取固件失败，请检测网络，或者网址是否正确！"
                exit 1
            fi
        else
            echo "通过https://ghproxy.com/代理下载固件中..."
            wget -q --timeout=5 --tries=2 --show-progress https://ghproxy.com/${URL_Download_Release}/${Firmware_to_download} -O ${Firmware_Path}/${firmware_downloaded}
            if [[ $? -ne 0 ]];then
                curl -fsSL https://ghproxy.com/${URL_Download_Release}/${Firmware_to_download} -O ${Firmware_Path}/${firmware_downloaded}
                if [[ $? -ne 0 ]];then
                    __error_msg "固件下载失败，请检测网络，或者网址是否正确！"
                    exit 1
                fi
            fi
        fi
        local imgsize=$(ls -l ${Firmware_Path}/${firmware_downloaded} | awk '{print ($5)/1048576;}')
        __success_msg "固件镜像：下载成功! 固件大小：${imgsize}MB"
    else
        __error_msg "已选为空，未知错误"
        exit 1
    fi
    

    echo
    __yellow_color "更新OpenWrt CT模板"
    if [[ -f /var/lib/vz/template/cache/openwrt.rootfs.tar.gz ]]; then
        rm -f /var/lib/vz/template/cache/openwrt.rootfs.tar.gz
    fi
    
    if [[ "${firmware_ext}" == ".tar.gz" ]]; then
        mv -f ${Firmware_Path}/${firmware_downloaded} /var/lib/vz/template/cache/
        __success_msg "CT模板：上传成功！"
    elif [[ "${firmware_ext}" == ".img.gz" ]]; then
        __green_color "解包OpenWrt img镜像..."
        cd ${Firmware_Path} && gzip -d ${firmware_downloaded} && unsquashfs openwrt.rootfs.img
        __green_color "CT模板：上传至/var/lib/vz/template/cache目录..."
        cd ${Firmware_Path}/squashfs-root && tar zcf /var/lib/vz/template/cache/openwrt.rootfs.tar.gz ./* && cd ../.. && rm -rf ${Firmware_Path}
        __success_msg "CT模板：上传成功！"
    fi
}

# 容器ID
function pct_id(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt容器ID[默认100]：" input_id || echo
        input_id=${input_id:-100}
        check_input_id=`echo ${input_id} | sed 's/[0-9]//g'`
        if [[ -n $check_input_id ]]; then
            __error_msg "输入错误，请重新输入！"
        elif [[ ${input_id} -lt 100 ]]; then
            __error_msg "当前输入ID<100，请重新输入！"
        else
            Lxc_id=${input_id}
            break
        fi
    done
}

# 容器名称
function pct_hostname(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt容器名称[默认OpenWrt]：" input_hostname || echo
        input_hostname=${input_hostname:-OpenWrt}
        local check_input_hostname=`echo ${input_hostname} | sed 's/[a-zA-Z0-9]//g' | sed 's/[_.-]//g'`
        if [[ -n $check_input_hostname ]]; then
            __error_msg "输入错误，请重新输入！"
        else
            Lxc_hostname=${input_hostname}
            break
        fi
    done
}

# 分区大小
function pct_rootfssize(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt分区大小[GB，默认2]：" input_rootfssize || echo
        input_rootfssize=${input_rootfssize:-2}
        local check_input_rootfssize=`echo ${input_rootfssize} | sed 's/[0-9]//g'`
        if [[ -n $check_input_rootfssize ]]; then
            __error_msg "输入错误，请重新输入！"
        elif [[ ${input_rootfssize} == 0 ]]; then
            __error_msg "不能为0，请重新输入！"
        else
            Lxc_rootfssize=${input_rootfssize}
            break
        fi
    done
}

# CPU核心数
function pct_cores(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt CPU核心数[默认4]：" input_cores || echo
        input_cores=${input_cores:-4}
        local check_input_cores=`echo ${input_cores} | sed 's/[0-9]//g'`
        if [[ -n $check_input_cores ]]; then
            __error_msg "输入错误，请重新输入！"
        elif [[ ${input_cores} == 0 ]]; then
            __error_msg "不能为0，请重新输入！"
        else
            Lxc_cores=${input_cores}
            break
        fi
    done
}

# 内存大小
function pct_memory(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt内存大小[MB，默认2048]：" input_memory || echo
        input_memory=${input_memory:-2048}
        local check_input_memory=`echo ${input_memory} | sed 's/[0-9]//g'`
        if [[ -n $check_input_memory ]]; then
            __error_msg "输入错误，请重新输入！"
        elif [[ ${input_memory} == 0 ]]; then
            __error_msg "不能为0，请重新输入！"
        else
            Lxc_memory=${input_memory}
            break
        fi
    done
}

# 开机自启
function pct_onboot(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt是否开机自启[0关闭，1开启，默认1]：" input_onboot || echo
        input_onboot=${input_onboot:-1}
        case ${input_onboot} in
        0)
            Lxc_order=2
            break
        ;;
        1)
            pct_order
            break
        ;;
        *)
            __error_msg "输入错误，请重新输入！"
        ;;
        esac
    done
}

# 启动顺序
function pct_order(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt启动顺序[默认2]：" input_order || echo
        input_order=${input_order:-2}
        local check_input_order=`echo ${input_order} | sed 's/[0-9]//g'`
        if [[ -n $check_input_order ]]; then
            __error_msg "输入错误，请重新输入！"
        elif [[ ${input_order} == 0 ]]; then
            __error_msg "不能为0，请重新输入！"
        else
            Lxc_order=${input_order}
            break
        fi
    done
}

# 网络接口设置
function pct_net(){
    echo
    while :; do
        read -t 30 -p "请输入OpenWrt网络接口数量[n取1-4，vmbr0为PVE自带，其它需在PVE网络中创建，默认1]：" input_net || echo
        input_net=${input_net:-1}
        case ${input_net} in
        1)
			cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
			pct create ${Lxc_id} \\
			local:vztmpl/openwrt.rootfs.tar.gz \\
			--rootfs local-lvm:${Lxc_rootfssize} \\
			--ostype unmanaged \\
			--hostname ${Lxc_hostname} \\
			--arch amd64 \\
			--cores ${Lxc_cores} \\
			--memory ${Lxc_memory} \\
			--swap 0 \\
			--net0 bridge=vmbr0,name=eth0 \\
			--unprivileged 0 \\
			--features nesting=1 \\
			--onboot ${Lxc_onboot} \\
			--startup order=${Lxc_order}
			EOF
            break
        ;;
        2)
			cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
			pct create ${Lxc_id} \\
			local:vztmpl/openwrt.rootfs.tar.gz \\
			--rootfs local-lvm:${Lxc_rootfssize} \\
			--ostype unmanaged \\
			--hostname ${Lxc_hostname} \\
			--arch amd64 \\
			--cores ${Lxc_cores} \\
			--memory ${Lxc_memory} \\
			--swap 0 \\
			--net0 bridge=vmbr0,name=eth0 \\
			--net1 bridge=vmbr1,name=eth1 \\
			--unprivileged 0 \\
			--features nesting=1 \\
			--onboot ${Lxc_onboot} \\
			--startup order=${Lxc_order}
			EOF
            break
        ;;
        3)
			cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
			pct create ${Lxc_id} \\
			local:vztmpl/openwrt.rootfs.tar.gz \\
			--rootfs local-lvm:${Lxc_rootfssize} \\
			--ostype unmanaged \\
			--hostname ${Lxc_hostname} \\
			--arch amd64 \\
			--cores ${Lxc_cores} \\
			--memory ${Lxc_memory} \\
			--swap 0 \\
			--net0 bridge=vmbr0,name=eth0 \\
			--net1 bridge=vmbr1,name=eth1 \\
			--net2 bridge=vmbr2,name=eth2 \\
			--unprivileged 0 \\
			--features nesting=1 \\
			--onboot ${Lxc_onboot} \\
			--startup order=${Lxc_order}
			EOF
            break
        ;;
        4)
			cat > ${Creatlxc_Path}/creat_openwrt <<-EOF
			pct create ${Lxc_id} \\
			local:vztmpl/openwrt.rootfs.tar.gz \\
			--rootfs local-lvm:${Lxc_rootfssize} \\
			--ostype unmanaged \\
			--hostname ${Lxc_hostname} \\
			--arch amd64 \\
			--cores ${Lxc_cores} \\
			--memory ${Lxc_memory} \\
			--swap 0 \\
			--net0 bridge=vmbr0,name=eth0 \\
			--net1 bridge=vmbr1,name=eth1 \\
			--net2 bridge=vmbr2,name=eth2 \\
			--net3 bridge=vmbr3,name=eth3 \\
			--unprivileged 0 \\
			--features nesting=1 \\
			--onboot ${Lxc_onboot} \\
			--startup order=${Lxc_order}
			EOF
            break
        ;;
        *)
            __error_msg "输入错误，请重新输入！"
        ;;
        esac
    done

}

# 创建lxc容器I
function creat_lxc_openwrt(){
    [[ ! -d ${Creatlxc_Path} ]] && mkdir -p ${Creatlxc_Path} || rm -rf ${Creatlxc_Path}/*
    
    echo
    __yellow_color "开始创建OpenWrt lxc容器..."
    pct_id
    pct_hostname
    pct_rootfssize
    pct_cores
    pct_memory
    pct_onboot
    pct_net
    
    echo
    local enable_configre_covery=n
    while :; do
        read -t 30 -p "是否保留OpenWrt配置？[y/Y或n/N，默认y]：" enable_config_backup || echo
        enable_config_backup=${enable_config_backup:-y}
        case ${enable_config_backup} in
        y|Y)
            echo
            local openwrtstatus=`pct status ${Lxc_id} | awk '{print $2}'`
            case ${openwrtstatus} in
            running)
                __green_color "正在备份配置..."
                config_backup
                enable_configre_covery=y
            ;;
            stopped)
                __green_color "OpenWrt处于关机状态，马上为您开机！"
                start_openwrt
                __green_color "正在备份配置..."
                config_backup
                enable_configre_covery=y
            ;;
            *)
                __warning_msg "容器不存在，无需备份！"
            ;;
            esac
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
    
    if [[ -n `ls /dev/disk/by-id | grep "${Lxc_id}--disk"` ]]; then
        echo
        __warning_msg "是否删除${Lxc_id}容器，然后继续？"
        while :; do
            read -t 60 -p "[y/Y或n/N，默认y]：" input_creatlxc || echo
            input_creatlxc=${input_creatlxc:-y}
            case ${input_creatlxc} in
            y|Y)
                echo
                __green_color "正在删除${Lxc_id}容器..."
                pct destroy ${Lxc_id} --destroy-unreferenced-disks 1 --purge 1 --force 1
                break
            ;;
            n|N)
                menu
                break
            ;;
            *)
                __error_msg "输入错误，请重新输入！"
            ;;
            esac
        done
    fi
    
    if [[ -f ${Creatlxc_Path}/creat_openwrt ]]; then
        echo
        __green_color "正在创建新容器..."
        bash ${Creatlxc_Path}/creat_openwrt
        if [[ $? -ne 0 ]]; then
            __error_msg "pct命令执行错误！"
            exit 1
        else
            __success_msg "lxc容器OpenWrt创建成功！"
        fi
        start_openwrt
        [[ ${enable_configre_covery} == y ]] && config_recovery
    fi
}

# 备份OpenWrt设置
function config_backup(){
    [[ ! -d ${Backup_Path} ]] && mkdir -p ${Backup_Path} || rm -rf ${Backup_Path}/*
    
    if [[ ! -f ${Upgrade_file} ]]; then
        pct pull ${Lxc_id} /etc/sysupgrade.conf ${Upgrade_file}
    fi
    
    while read line; do
        local linehead=`echo "${line}" | cut -c 1`
        if [[ ${linehead} == "/" ]]; then
            local back_file=${Backup_Path}${line}
            echo "备份OpenWrt：${line}"
            [[ ! -d ${Backup_Path}`dirname "${line}"` ]] && mkdir -p ${Backup_Path}`dirname "${line}"`
            pct pull ${Lxc_id} ${line} ${back_file}
        fi
    done < ${Upgrade_file}
    __success_msg "OpenWrt的相关文件已经备份至:${Backup_Path}"
}

# 启动OpenWrt
function start_openwrt(){
    echo
    __green_color "启动OpenWrt，请耐心等待约1分钟..."
    sleep 5
    pct start ${Lxc_id}
    sleep 30
    local times=0
    while :; do
        let times+=1
        pct exec ${Lxc_id} -- ping -c 1 223.5.5.5
        if [[ $? -ne 0 ]] && [[ ${times} -le 5 ]]; then                
            echo "OpenWrt启动中... 10s后进行第${times}次尝试！"
            sleep 10
        elif [[ $? -ne 0 ]] && [[ ${times} -gt 5 ]]; then
            __error_msg "OpenWrt启动失败！请手动启动后按 [Enter] 键继续！"
            echo
            pause
            times=0
        else
            __success_msg "OpenWrt启动成功！"
            break
        fi
    done
}

# 恢复OpenWrt设置
function config_recovery(){
    echo
    __green_color "开始恢复配置..."
    while read line; do
        local linehead=`echo "${line}" | cut -c 1`
        if [[ ${linehead} == "/" ]]; then
            local rec_file=${Backup_Path}${line}
            if [[ -s ${rec_file} ]]; then
                echo "恢复OpenWrt：${line}"
                pct push ${Lxc_id} ${rec_file} ${line}
                if [[ $? -ne 0 ]]; then
                    __error_msg "恢复${line}失败！"
                else
                    __green_color "OK!"
                fi
            fi
        fi
    done < ${Upgrade_file}
    __success_msg "恢复配置完成！"
}

# 安装工具
function install_tools(){
    echo
    __yellow_color "开始检测脚本依赖..."
    local pve_pkgs=(curl wget squashfs-tools)
    apt update > /dev/null 2>&1
    for pkg in ${pve_pkgs[*]}; do
        if [[ $(apt list --installed 2>/dev/null | grep -Eo "^${pkg}\/" | wc -l) -ge 1 ]]; then
            __info_msg "${pkg} 已安装"
        else
            __warning_msg "${pkg} 未安装"
            __green_color "开始安装${pkg} ..."
            apt install -y ${pkg} 2>/dev/null
        fi
    done
}

# 升级脚本
function version_download() {
    [[ ! -d ${Script_Path} ]] && mkdir -p ${Script_Path} || rm -rf ${Script_Path}/*
    
    Google_check="$(curl -I -s --connect-timeout 3 google.com -w %{http_code} | tail -n1)"

    if [[ "${Google_check}" == "301" ]];then
        wget -q --timeout=5 --tries=2 ${URL_Download_Version} -o ${Script_Path}/version
        if [[ $? -ne 0 ]];then
            return
        fi
    else
        wget -q --timeout=5 --tries=2 https://ghproxy.com/${URL_Download_Version} -O ${Script_Path}/version
        if [[ $? -ne 0 ]]; then
            curl -fsSL https://ghproxy.com/${URL_Download_Version} -o ${Script_Path}/version
            if [[ $? -ne 0 ]];then
                return
            fi
        fi
    fi
    
    chmod +x ${Script_Path}/version
}

function script_download() {
    if [[ "${Google_check}" == "301" ]];then
        curl -fsSL ${URL_Download_Script} -o ${Script_Path}/openwrt
        if [[ $? -ne 0 ]];then
            wget -q --timeout=5 --tries=2 ${URL_Download_Script} -o ${Script_Path}/openwrt
            if [[ $? -ne 0 ]];then
                __error_msg "脚本更新失败，请检查网络，重试！"
                return
            fi
        fi
    else
        curl -fsSL https://ghproxy.com/${URL_Download_Script} -o ${Script_Path}/openwrt
        if [[ $? -ne 0 ]]; then
            wget -q --timeout=5 --tries=2 https://ghproxy.com/${URL_Download_Script} -o ${Script_Path}/openwrt
            if [[ $? -ne 0 ]];then
                __error_msg "脚本更新失败，请检查网络，重试！"
                return
            fi
        fi
    fi
    
    if [[ -s ${Script_Path}/openwrt ]];then
        cp -f ${Script_Path}/openwrt /usr/bin/openwrt && chmod +x /usr/bin/openwrt
        __success_msg "脚本更新成功，请退出重新运行！"
    fi
}

function script_udpate() {
    if [[ -s ${Script_Path}/version ]]; then
        source ${Script_Path}/version
    fi
    
    if [[ -z ${LatestVersion_Openwrt} ]]; then
        __error_msg "获取版本信息失败，或网络不稳定，请稍后再试！"
        return
    fi
    
    while :; do
        clear
cat <<-EOF
`__red_color \
"     OpenWrt自动安装升级脚本  ${Version}"`
┌────────────────────────────────────────────┐
      最新版本: ${LatestVersion_Openwrt}
      当前版本: ${Version}
└────────────────────────────────────────────┘
EOF
        echo -ne "是否升级[y/Y或n/N，默认n]:"
        read -t 30 enable_script_udpate
        enable_script_udpate=${enable_script_udpate:-n}
        case ${enable_script_udpate} in
        y|Y)
            script_download
            break
        ;;
        n|N)
            menu
            break
        ;;
        *)
            __error_msg "输入错误，请重新输入！"
        ;;
        esac
    done
}

# 帮助
function script_help() {
    clear
    cat <<-EOF
    =============================================================================================

    `__yellow_color "1. 固件编译"`

        a. 编译前
           make meunconfig --> targert images --> 选中 [*] tar.gz，编译openwrt...rootfs.tar.gz
           或
           make meunconfig --> targert images --> 选中 [*] GZip images，编译openwrt...rootfs.img.gz
        b. 编译后
           将xxx.rootfs.tar.gz/xxx.rootfs.img.gz上传至release
        c. 固件下载、安装
           只需要有.tar.gz或.img.gz格式的固件，完成简单设置即可下载安装lxc固件

    ---------------------------------------------------------------------------------------------

    `__yellow_color "2. 网络接口"`

        网络接口数量>1时，需自建网络接口。
        网络接口数量1：无需创建，使用系统默认vmbr0；
        网络接口数量2：vmbr1；
        网络接口数量3：vmbr1、vmbr2；
        网络接口数量4：vmbr1、vmbr2、vmbr3。

    ---------------------------------------------------------------------------------------------

    `__yellow_color "3. 设置保存"`

        a. 需要保留的配置，请将文件路径存放在OpenWrt系统/etc/sysupgrade.conf文件中，格式如下：
            ## This file contains files and directories that should
            ## be preserved during an upgrade.
            /etc/config/passwall
            
           注：在此文件结尾请保留一行空白行！
        b. 在运行过一次本脚本后，该文件自动保存至PVE系统/etc/openwrt.upgrade文件中，
           后续在PVE系统内修改即可。
        c. 从OpenWrt下载的相应备份文件，放在PVE系统/root/openwrt文件夹，有备份丢失，可手动恢复。

    =============================================================================================
EOF
}

# 检测脚本运行环境
function linux_uname(){
    if [[ -n `uname -a | grep -i "OpenWrt"` ]]; then
        clear
        echo "`uname -a`"
        echo
        __error_msg "脚本需运行在PVE环境，检测当前为OpenWrt！"
        echo
        echo "────────────────────────────────────────────────────────────────────────────"
        echo
        echo "第1步：PVE系统命令行下载文件"
        __green_color "wget https://ghproxy.com/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/bin/openwrt && chmod -f +x /usr/bin/openwrt"
        echo
        echo "第2步：PVE系统命令行输入"
        __green_color "openwrt"
        echo
        echo "────────────────────────────────────────────────────────────────────────────"
        echo
        exit 1
    fi
}

# 清空文件
function files_clean(){
    [[ -d ${Openwrt_Path} ]] && rm -rf ${Openwrt_Path} > /dev/null 2>&1
}

# 主菜单
function menu(){
	load_settings
    clear
    
    cat <<-EOF
`__red_color "     OpenWrt自动安装升级脚本  ${Version}"`
┌────────────────────────────────────────────┐
   安  1. 下载固件+更新CT模板+创建LXC容器
   装  2. 下载固件+更新CT模板
   更  3. 创建LXC容器
   新  4. 备份OpenWrt文件
  ──────────────────────────────────────────
       5. 安装依赖(curl...)
       6. 升级脚本
       7. 设置
       8. 帮助
       0. 退出
└────────────────────────────────────────────┘
EOF
    echo -ne "请选择: [ ]\b\b"
    read -t 60 menuid
    menuid=${menuid:-0}
    case ${menuid} in
    1)
        update_CT_Templates
        creat_lxc_openwrt
        echo
        __green_color "10s后，将清理残留文件..."
        sleep 10
        files_clean
        echo
        pause
        menu
    ;;
    2)
        update_CT_Templates
        echo
        pause
        menu
    ;;
    3)
        creat_lxc_openwrt
        echo
        pause
        menu
    ;;
    4)
        pct_id
        config_backup
        echo
        pause
        menu
    ;;
    5)
        install_tools
        echo
        pause
        menu
    ;;
    6)
        script_udpate
        echo
        pause
        menu
    ;;
    7)
        settings_modify
        echo
        pause
        menu
    ;;
    8)
        script_help
        echo
        pause
        menu
    ;;
    0)
        files_clean
        clear
        exit 0
    ;;
    *)
        menu
    ;;
    esac
}


linux_uname
init_settings
version_download&
menu
