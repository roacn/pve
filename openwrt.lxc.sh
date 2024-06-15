#!/bin/bash
##########################################################
# URL: https://github.com/roacn/pve
# Description: AutoUpdate for Openwrt
# Author: Ss.
# Please use the PVE command line to run the shell script.
##########################################################

Version=v2.1.4

Settings_File="/etc/openwrt.conf"
Upgrade_File="/etc/openwrt.upgrade"
Backup_Path="/root/openwrt"
Openwrt_Path="/tmp/openwrt"
Firmware_Path="/tmp/openwrt/firmware"
Script_Path="/tmp/openwrt/script"
Lxc_Path="/tmp/openwrt/lxc"
Bak_Path="/tmp/openwrt/bak"

Proxy_Primary="https://mirror.ghproxy.com"
Proxy_Secondary="https://ghproxy.net"
CDN_Jsdelivr="https://cdn.jsdelivr.net/gh"
Mirror_Fastgit="https://download.fastgit.org"

URL_Version_Origin="https://raw.githubusercontent.com/roacn/pve/main/lxc/version"
URL_Version_Primary="$Proxy_Primary/$URL_Version_Origin"
URL_Version_Secondary="$CDN_Jsdelivr/roacn/pve/lxc/version"

URL_Script_Origin="https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh"
URL_Script_Primary="$Proxy_Primary/$URL_Script_Origin"
URL_Script_Secondary="$CDN_Jsdelivr/roacn/pve/openwrt.lxc.sh"


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
    if [[ -n $input ]]; then
        echo -e "\b\n"
    fi
}

function settings_init() {
    [[ ! -d $Openwrt_Path ]] && mkdir -p $Openwrt_Path
    
    if [[ ! -f $Settings_File ]]; then
cat > $Settings_File <<-EOF
Repository="roacn/openwrt"
Tag_name="AutoUpdate-x86-lxc"
Github_api="zzz_api"
Priority="default"
Lxc_id=100
Lxc_hostname="OpenWrt"
Lxc_cores=4
Lxc_memory=1024
Lxc_swap=512
Lxc_rootfssize=2
Lxc_onboot=0
Lxc_order=1
Lxc_net=1
Google_check=0
EOF
        chmod +x $Settings_File
        __warning_msg "首次运行，使用默认设置，如需修改，请到主菜单'设置'选项."
        pause
    else
        need_settings_save="false"
        default_settings=()

        source $Settings_File

        if [[ -z $Repository ]]; then
            Repository="roacn/openwrt"
            need_settings_save="true"
            default_settings+=("GitHub 仓库地址")
        fi
        if [[ -z $Tag_name ]]; then
            Tag_name="AutoUpdate-x86-lxc"
            need_settings_save="true"
            default_settings+=("GitHub TAG标签名")
        fi
        if [[ -z $Github_api ]]; then
            Github_api="zzz_api"
            need_settings_save="true"
            default_settings+=("GitHub API文件名")
        fi
        if [[ -z $Priority ]]; then
            Priority="default"
            need_settings_save="true"
            default_settings+=("固件格式")
        fi
        if [[ -z $Lxc_id ]]; then
            Lxc_id=100
            need_settings_save="true"
            default_settings+=("LXC 容器ID")
        fi
        if [[ -z $Lxc_hostname ]]; then
            Lxc_hostname="OpenWrt"
            need_settings_save="true"
            default_settings+=("LXC 容器名称")
        fi
        if [[ -z $Lxc_cores ]]; then
            Lxc_cores=4
            need_settings_save="true"
            default_settings+=("LXC CPU核心数")
        fi
        if [[ -z $Lxc_memory ]]; then
            Lxc_memory=1024
            need_settings_save="true"
            default_settings+=("LXC 内存分配")
        fi
        if [[ -z $Lxc_rootfssize ]]; then
            Lxc_rootfssize=2
            need_settings_save="true"
            default_settings+=("LXC 根磁盘大小")
        fi
        if [[ -z $Lxc_swap ]]; then
            Lxc_swap=512
            need_settings_save="true"
            default_settings+=("LXC 交换分区")
        fi
        if [[ -z $Lxc_onboot ]]; then
            Lxc_onboot=0
            need_settings_save="true"
            default_settings+=("LXC 开机自启")
        fi
        if [[ -z $Lxc_order ]]; then
            Lxc_order=1
            need_settings_save="true"
            default_settings+=("LXC 启动顺序")
        fi
        if [[ -z $Lxc_net ]]; then
            Lxc_net=1
            need_settings_save="true"
            default_settings+=("LXC 网络接口数量")
        fi


        if [[ $need_settings_save == "true" ]]; then
            if [ ${#default_settings[@]} -gt 0 ]; then
                __warning_msg "以下配置项未设置，已自动应用默认值，并将保存至 $Settings_File 配置文件："
                for setting in "${default_settings[@]}"; do
                    __warning_msg "  - $setting"
                done
                __warning_msg "如需修改，请前往设置菜单。"
            fi
            pause
            settings_save
        fi
    fi
}

function settings_load() {
    source $Settings_File
    URL_Github_Api="https://api.github.com/repos/${Repository}/releases/tags/${Tag_name}"
    URL_Release_Origin="https://github.com/${Repository}/releases/download/${Tag_name}"
    URL_Release_Primary="$Proxy_Primary/$URL_Release_Origin"
    URL_Release_Secondary="$Proxy_Secondary/$URL_Release_Origin"
    #URL_Release_Fastgit="$Mirror_Fastgit/${Repository}/releases/download/${Tag_name}"
}

function settings_modify() {
    while :; do
    settings_load
    clear
cat <<-EOF
`__green_color "     OpenWrt自动安装升级脚本  $Version"`
┌────────────────────────────────────────────────────┐
      仓库地址: $Repository
      TAG 名称: $Tag_name
      API 文件: $Github_api
      固件格式: $Priority
  ──────────────────────────────────────────────────
      容器  ID: $Lxc_id
      容器名称: $Lxc_hostname
      CPU 核心: $Lxc_cores
      内存大小: $Lxc_memory MB
      磁盘大小: $Lxc_rootfssize GB
      交换分区: $Lxc_swap MB
      开机自启: $Lxc_onboot
      启动顺序: $Lxc_order
      网络接口: $Lxc_net
└────────────────────────────────────────────────────┘
EOF
        echo -ne "Y/y修改配置，N/n不修改配置："
        read -t 60 enable_settings_modify
        enable_settings_modify=${enable_settings_modify:-n}
        case $enable_settings_modify in
        y|Y)
            set_github_repository
            set_release_tag
            set_release_api
            set_firmware_format
            set_pct_id
            set_pct_hostname
            set_pct_rootfssize
            set_pct_cores
            set_pct_memory
            set_pct_swap
            set_pct_onboot
            set_pct_net
            settings_save
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

function settings_save() {
cat > $Settings_File <<-EOF
Repository="$Repository"
Tag_name="$Tag_name"
Github_api="$Github_api"
Priority="$Priority"
Lxc_id=$Lxc_id
Lxc_hostname="$Lxc_hostname"
Lxc_cores=$Lxc_cores
Lxc_memory=$Lxc_memory
Lxc_swap=$Lxc_swap
Lxc_rootfssize=$Lxc_rootfssize
Lxc_onboot=$Lxc_onboot
Lxc_order=$Lxc_order
Lxc_net=$Lxc_net
Google_check=$Google_check
EOF

    __success_msg "设置已保存！"
}

function settings_show() {
    echo
    __green_color "当前配置："
    __green_color "  ──────────────────────────────────────────────────"
    echo "    容器  ID: $Lxc_id"
    echo "    容器名称: $Lxc_hostname"
    echo "    CPU 核心: $Lxc_cores"
    echo "    内存大小: $Lxc_memory MB"
    echo "    磁盘大小: $Lxc_rootfssize GB"
    echo "    交换分区: $Lxc_swap MB"
    echo "    开机自启: $Lxc_onboot"
    echo "    启动顺序: $Lxc_order"
    echo "    网络接口: $Lxc_net"
    __green_color "  ──────────────────────────────────────────────────"
}

function set_github_repository() {
    echo
    read -t 60 -p "请输入仓库地址 [用户名/仓库名, 默认roacn/openwrt]:" input_repo || echo
    input_repo=${input_repo:-"roacn/openwrt"}
    Repository="${input_repo}"
}

function set_release_tag() {
    echo
    read -t 60 -p "请输入tag名称 [默认AutoUpdate-x86-lxc]:" input_tag || echo
    input_tag=${input_tag:-"AutoUpdate-x86-lxc"}
    Tag_name="${input_tag}"
}

function set_release_api() {
    echo
    read -t 60 -p "请输入api文件名称 [默认zzz_api]:" input_api || echo
    input_api=${input_api:-"zzz_api"}
    Github_api="${input_api}"
}

function set_firmware_format() {
    echo
    echo "请输入固件格式选择:"
    echo "0. .tar.gz或.img.gz格式固件;"
    echo "1. 只选.tar.gz格式固件;"
    echo "2. 只选.img.gz格式固件;"
    while :; do
        read -t 60 -p "请输入数字 [默认0]:" input_priority || echo
        input_priority=${input_priority:-0}
        case $input_priority in
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

function network_check() {
    settings_load
    local code="$(curl -I -s --connect-timeout 3 google.com -w %{http_code} | tail -n1)"

    if [[ $(cat $Settings_File | grep -c "Google_check") -eq 0 ]]; then
        echo Google_check=$code >> $Settings_File
    elif [[ "$code" != "$Google_check" ]]; then
        sed -i "s/^Google_check=.*/Google_check=$code/g" $Settings_File
    fi
}

function release_choose(){
    echo
    local firmware_list_multi="$Firmware_Path/firmware_list_multi"
    local firmware_list_tar="$Firmware_Path/firmware_list_tar"
    local firmware_list_img="$Firmware_Path/firmware_list_img"
    local firmware_multi=$(grep -E "\"name\"" $Firmware_Path/$Github_api | grep -i -Eo ".*rootfs.*\.gz" | sed "s/ //g" | sed "s/\"//g" | awk -F ':' '{print $2;}' | sort -r)
    local firmware_tar=$(echo "$firmware_multi" | grep -i -E ".*\.tar.*\.gz")
    local firmware_img=$(echo "$firmware_multi" | grep -i -E ".*\.img.*\.gz")
    echo "$firmware_multi" > $firmware_list_multi
    echo "$firmware_tar" > $firmware_list_tar
    echo "$firmware_img" > $firmware_list_img
    
    if [[ $Priority == ".tar.gz" ]]; then
        firmware_list=$firmware_list_tar
    elif [[ $Priority == ".img.gz" ]]; then
        firmware_list=$firmware_list_img
    else
        firmware_list=$firmware_list_multi
    fi
    
    echo "Github云端固件:"
    nl "$firmware_list"
    if [[ -z $firmware_list ]]; then
        __error_msg "当前云端固件列表为空，请检查！"
        exit 1
    fi
    
    while :; do
        read -t 120 -p "请输入固件对应序号 [默认1]:" input_release
        input_release=${input_release:-1}
        check_input_release=`echo $input_release | sed 's/[0-9]//g'`
        if [[ -n $check_input_release ]]; then
            __error_msg "输入错误，请输入数字！"
        elif [[ $input_release -eq 0 ]] || [[ $input_release -gt $(cat $firmware_list | wc -l) ]]; then
            __error_msg "超出范围，请重新输入！"
        else
            Firmware_to_download=$(cat $firmware_list | head -n $input_release | tail -n 1)
            __green_color " [已选] $Firmware_to_download"
            break
        fi
    done
}

function ct_update(){
    settings_load
    [[ ! -d $Firmware_Path ]] && mkdir -p $Firmware_Path || rm -rf $Firmware_Path/*
    echo
    __yellow_color "下载OpenWrt固件"
    
    ping 223.5.5.5 -c 1 -W 2 > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        __error_msg "网络连接错误!"
        exit 1
    fi
    
    echo
    __green_color "获取固件API信息..."
    rm -rf $Firmware_Path/$Github_api
    [[ -z $Google_check ]] && network_check
    if [[ $Google_check -eq 301 ]];then
        wget -q --timeout=5 --tries=2 $URL_Github_Api -O $Firmware_Path/$Github_api
        if [[ $? -ne 0 ]];then
            curl -fsSL $URL_Github_Api -o $Firmware_Path/$Github_api
            if [[ $? -ne 0 ]];then
                __error_msg "直连github获取固件API信息失败，请检测网络，或网址是否正确！"
                exit 1
            fi
        fi
    else
        wget -q --timeout=5 --tries=2 "$URL_Release_Primary/$Github_api" -O $Firmware_Path/$Github_api
        if [[ $? -ne 0 ]]; then
            wget -q --timeout=5 --tries=2 "$URL_Release_Secondary/$Github_api" -O $Firmware_Path/$Github_api
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
    local firmware_downloaded="openwrt.rootfs$firmware_ext"

    echo
    __green_color "开始下载固件..."
    if [[ -n $Firmware_to_download ]];then
        if [[ $Google_check -eq 301 ]];then
            wget -q --timeout=5 --tries=2 --show-progress $URL_Release_Origin/$Firmware_to_download -O $Firmware_Path/$firmware_downloaded
            if [[ $? -ne 0 ]];then
                __error_msg "获取固件失败，请检测网络，或者网址是否正确！"
                exit 1
            fi
        else
            echo "通过$Proxy_Primary/代理下载固件中..."
            wget -q --timeout=5 --tries=2 --show-progress $URL_Release_Primary/$Firmware_to_download -O $Firmware_Path/$firmware_downloaded
            if [[ $? -ne 0 ]];then
                echo "通过$Proxy_Secondary/代理下载固件中..."
                wget -q --timeout=5 --tries=2 --show-progress $URL_Release_Secondary/$Firmware_to_download -O $Firmware_Path/$firmware_downloaded
                if [[ $? -ne 0 ]];then
                    __error_msg "固件下载失败，请检测网络，或者网址是否正确！"
                    exit 1
                fi
            fi
        fi
        local imgsize=$(ls -l $Firmware_Path/$firmware_downloaded | awk '{print ($5)/1048576;}')
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
    
    if [[ $firmware_ext == ".tar.gz" ]]; then
        mv -f $Firmware_Path/$firmware_downloaded /var/lib/vz/template/cache/
        __success_msg "CT模板：上传成功！"
    elif [[ $firmware_ext == ".img.gz" ]]; then
        __green_color "解包OpenWrt img镜像..."
        cd $Firmware_Path && gzip -d $firmware_downloaded && unsquashfs openwrt.rootfs.img
        __green_color "CT模板：上传至/var/lib/vz/template/cache目录..."
        cd $Firmware_Path/squashfs-root && tar zcf /var/lib/vz/template/cache/openwrt.rootfs.tar.gz ./* && cd ../.. && rm -rf $Firmware_Path
        __success_msg "CT模板：上传成功！"
    fi
}

function set_pct_id(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt容器ID [默认100]:" input_id || echo
        input_id=${input_id:-100}

        if ! [[ $input_id =~ ^[0-9]+$ ]]; then
            __error_msg "输入错误，请输入数字！"
        elif (( input_id < 100 )); then
            __error_msg "当前输入ID<100，请重新输入！"
        else
            Lxc_id=$input_id
            break
        fi
    done
}

function set_pct_hostname(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt容器名称 [默认OpenWrt]:" input_hostname || echo
        input_hostname=${input_hostname:-OpenWrt}
        local check_input_hostname=`echo $input_hostname | sed 's/[a-zA-Z0-9]//g' | sed 's/[_.-]//g'`
        if [[ -n $check_input_hostname ]]; then
            __error_msg "输入错误，请重新输入！"
        else
            Lxc_hostname=$input_hostname
            break
        fi
    done
}

function set_pct_rootfssize(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt磁盘大小 [单位GB, 默认2]:" input_rootfssize || echo
        input_rootfssize=${input_rootfssize:-2}

        if ! [[ $input_rootfssize =~ ^[1-9][0-9]*$ ]]; then
            __error_msg "输入错误，请输入非零数字！"
        else
            Lxc_rootfssize=$input_rootfssize
            break
        fi
    done
}

function set_pct_cores(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt CPU核心数 [默认4]:" input_cores || echo
        input_cores=${input_cores:-4}

        if ! [[ $input_cores =~ ^[1-9][0-9]*$ ]]; then
            __error_msg "输入错误，请输入非零数字！"
        else
            Lxc_cores=$input_cores
            break
        fi
    done
}

function set_pct_memory(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt内存大小 [单位MB, 默认1024]:" input_memory || echo
        input_memory=${input_memory:-1024}

        if ! [[ $input_memory =~ ^[1-9][0-9]*$ ]]; then
            __error_msg "输入错误，请输入非零数字！"
        else
            Lxc_memory=$input_memory
            break
        fi
    done
}

function set_pct_swap(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt Swap交换区大小 [单位MB, PVE系统默认值512]:" input_swap || echo
        input_swap=${input_swap:-512}

        if ! [[ $input_swap =~ ^[1-9][0-9]*$ ]]; then
            __error_msg "输入错误，请输入非零数字！"
        else
            Lxc_swap=$input_swap
            break
        fi
    done
}

function set_pct_onboot(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt是否开机自启 [0关闭, 1开启, 默认1]:" input_onboot || echo
        input_onboot=${input_onboot:-1}
        case $input_onboot in
        0)
            Lxc_onboot=0
            Lxc_order=1
            break
        ;;
        1)
            Lxc_onboot=1
            set_pct_order
            break
        ;;
        *)
            __error_msg "输入错误，请重新输入！"
        ;;
        esac
    done
}

function set_pct_order(){
    echo
    while :; do
        read -t 60 -p "请输入OpenWrt启动顺序数字 [默认1]:" input_order || echo
        input_order=${input_order:-1}

        if [[ $input_order =~ ^[1-9][0-9]*$ ]]; then
            Lxc_order=$input_order
            break
        else
            __error_msg "输入错误，请输入非零数字！"
        fi
    done
}

function set_pct_net(){
    echo
    echo "网络接口vmbr0为PVE自带，其它需在PVE网络中手动创建"
    while :; do
        read -t 60 -p "请输入接口数量 [n取1-8, 默认1]:" input_net || echo
        input_net=${input_net:-1}
        if [[ $input_net -ge 1 ]] && [[ $input_net -le 8 ]]; then
            Lxc_net=$input_net
            break
        else
            __error_msg "输入有误，请重新输入！"
        fi
    done
}

function lxc_prepare() {
    if [[ $Lxc_net -lt 1 ]] || [[ $Lxc_net -gt 8 ]]; then
        __error_msg "网络接口数量配置有误！应为1至8之间的数字。"
        return 1
    fi

    local net_conf=""
    for ((i=0; i<$Lxc_net; i++)); do
        if [[ $i -eq $((Lxc_net-1)) ]]; then
            net_conf+="--net${i} bridge=vmbr${i},name=eth$i"
        else
            net_conf+="--net${i} bridge=vmbr${i},name=eth$i "
        fi
    done

    cat > $Lxc_Path/$Lxc_id <<-EOF
pct create $Lxc_id \\
local:vztmpl/openwrt.rootfs.tar.gz \\
--rootfs local-lvm:$Lxc_rootfssize \\
--ostype unmanaged \\
--hostname $Lxc_hostname \\
--arch amd64 \\
--cores $Lxc_cores \\
--memory $Lxc_memory \\
--swap $Lxc_swap \\
$net_conf \\
--unprivileged 0 \\
--features nesting=1 \\
--onboot $Lxc_onboot \\
--startup order=$Lxc_order
EOF
}

function lxc_create(){
    [[ ! -d $Lxc_Path ]] && mkdir -p $Lxc_Path || rm -rf $Lxc_Path/*
    
    settings_show

    read -t 120 -p "Y/y继续，N/n返回：" input_goon || echo
    input_goon=${input_goon:-y}
    case $input_goon in
    y|Y)
        echo
    ;;
    n|N)
        return
    ;;
    *)
        __error_msg "输入错误，请重新输入！"
    ;;
    esac
    
    __yellow_color "开始创建OpenWrt lxc容器..."
    
    lxc_prepare
    
    echo
    local enable_configre_covery=n
    while :; do
        read -t 60 -p "Y/y备份OpenWrt文件；N/n不备份OpenWrt配置：" enable_config_backup || echo
        enable_config_backup=${enable_config_backup:-y}
        case $enable_config_backup in
        y|Y)
            local openwrt_status=`pct status $Lxc_id | awk '{print $2}'`
            case $openwrt_status in
            running)
                config_backup
                enable_configre_covery=y
            ;;
            stopped)
                echo
                __green_color "OpenWrt处于关机状态，马上为您开机！"
                lxc_start
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
    
    if [[ -n `ls /dev/disk/by-id | grep "$Lxc_id--disk"` ]]; then
        echo
        __warning_msg "是否删除$Lxc_id容器？"
        while :; do
            read -t 60 -p "Y/y继续；N/n返回：" input_deletelxc || echo
            input_deletelxc=${input_deletelxc:-y}
            case $input_deletelxc in
            y|Y)
                echo
                __green_color "正在删除$Lxc_id容器..."
                pct destroy $Lxc_id --destroy-unreferenced-disks 1 --purge 1 --force 1
                break
            ;;
            n|N)
                return
            ;;
            *)
                __error_msg "输入错误，请重新输入！"
            ;;
            esac
        done
    fi
    
    if [[ -f $Lxc_Path/$Lxc_id ]]; then
        echo
        __green_color "正在创建新容器..."
        chmod +x $Lxc_Path/$Lxc_id
        bash $Lxc_Path/$Lxc_id
        if [[ $? -ne 0 ]]; then
            __error_msg "pct命令执行错误！"
            exit 1
        else
            __success_msg "lxc容器OpenWrt创建成功！"
        fi
        lxc_start
        [[ $enable_configre_covery == y ]] && config_recovery
    else
        __error_msg "未找到pct命令！"
        exit 1
    fi
}

function lxc_start(){
    echo
    __green_color "启动OpenWrt，请耐心等待约1分钟..."
    pct start $Lxc_id
    sleep 20
    local times=0
    while :; do
        let times+=1
        local openwrt_status=`pct status $Lxc_id | awk '{print $2}'`
        case $openwrt_status in
        running)
            __success_msg "OpenWrt启动成功！"
            break
        ;;
        *)
            if [[ $times -le 5 ]]; then                
                echo "OpenWrt启动中... 5s后进行第${times}次尝试！"
                sleep 5
            elif [[ $times -gt 5 ]]; then
                __error_msg "OpenWrt启动失败！请手动启动后，按 [Enter] 键继续！"
                pause
                times=0
            fi
        ;;
        esac
    done
}

function config_backup(){
    [[ ! -d $Bak_Path ]] && mkdir -p $Bak_Path || rm -rf $Bak_Path/*
    
    echo
    __green_color "开始备份配置..."
    if [[ ! -f $Upgrade_File ]]; then
        pct pull $Lxc_id /etc/sysupgrade.conf $Upgrade_File
    fi
    
    for file in $(cat $Upgrade_File | grep -E "^/"); do
        local bak_file=$Bak_Path$file
        echo "备份OpenWrt：$file"
        [[ ! -d $Bak_Path`dirname "$file"` ]] && mkdir -p $Bak_Path`dirname "${file}"`
        pct pull $Lxc_id $file $bak_file
    done
    
    [[ -d $Backup_Path ]] && rm -rf $Backup_Path
    mv -f $Bak_Path $Backup_Path
    __success_msg "OpenWrt的相关文件已经备份至:$Backup_Path"
}

function config_recovery(){
    echo
    __green_color "开始恢复配置..."
    if [[ ! -f $Upgrade_File ]]; then
        __error_msg "$Upgrade_File 不存在，无法进行恢复操作！"
        return
    fi
    for file in $(cat $Upgrade_File | grep -E "^/"); do
        local rec_file=$Backup_Path$file
        if [[ -s $rec_file ]]; then
            echo "恢复OpenWrt：$file"
            pct push $Lxc_id $rec_file $file  
            if [[ $? -ne 0 ]]; then
                __error_msg "恢复${line}失败！"
            fi
        fi
    done
    __success_msg "恢复配置完成！"
}

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
            apt install -y $pkg 2>/dev/null
        fi
    done
}

function script_version() {
    [[ ! -d $Script_Path ]] && mkdir -p $Script_Path || rm -rf $Script_Path/*
    [[ -z $Google_check ]] && network_check    
    if [[ $Google_check -eq 301 ]];then
        wget -q --timeout=5 --tries=2 $URL_Version_Origin -O $Script_Path/version
        if [[ $? -ne 0 ]];then
            curl -fsSL $URL_Version_Origin -o $Script_Path/version
            if [[ $? -ne 0 ]]; then
                return
            fi
        fi
    else
        wget -q --timeout=5 --tries=2 $URL_Version_Primary -O $Script_Path/version
        if [[ $? -ne 0 ]]; then
            wget -q --timeout=5 --tries=2 $URL_Version_Secondary -O $Script_Path/version
            if [[ $? -ne 0 ]]; then
                return
            fi
        fi
    fi
    
    chmod +x $Script_Path/version
}

function script_download() {
    if [[ $Google_check -eq 301 ]];then
        wget -q --timeout=5 --tries=2 $URL_Script_Origin -O $Script_Path/openwrt
        if [[ $? -ne 0 ]];then
            curl -fsSL $URL_Script_Origin -o $Script_Path/openwrt
            if [[ $? -ne 0 ]];then
                __error_msg "脚本更新失败，请检查网络，重试！"
                return
            fi
        fi
    else
        wget -q --timeout=5 --tries=2 $URL_Script_Primary -O $Script_Path/openwrt
        if [[ $? -ne 0 ]]; then
            wget -q --timeout=5 --tries=2 $URL_Script_Secondary -O $Script_Path/openwrt
            if [[ $? -ne 0 ]];then
                __error_msg "脚本更新失败，请检查网络，重试！"
                return
            fi
        fi
    fi
    
    if [[ -s $Script_Path/openwrt ]];then
        cp -f $Script_Path/openwrt /usr/bin/openwrt && chmod +x /usr/bin/openwrt
        __success_msg "脚本更新成功，请退出重新运行！"
    fi
}

function script_udpate() {
    settings_load
    script_version
    if [[ -s $Script_Path/version ]]; then
        source $Script_Path/version 2 > /dev/null
    fi
    
    if [[ -z $LatestVersion_Openwrt ]]; then
        __error_msg "获取版本信息失败，或网络不稳定，请稍后再试！"
        return
    fi
    
    while :; do
        clear
cat <<-EOF
`__green_color "     OpenWrt自动安装升级脚本  $Version"`
┌────────────────────────────────────────────────────┐
      最新版本: $LatestVersion_Openwrt
      当前版本: $Version
└────────────────────────────────────────────────────┘
EOF
        echo -ne "Y/y升级；N/n不升级："
        read -t 60 enable_script_udpate
        enable_script_udpate=${enable_script_udpate:-n}
        case $enable_script_udpate in
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
        网络接口数量1：无需创建，使用PVE系统默认vmbr0；
        网络接口数量2：需PVE自建vmbr1；
        网络接口数量3：需PVE自建vmbr1、vmbr2；
        网络接口数量4：需PVE自建vmbr1、vmbr2、vmbr3。
        ...
        网络接口数量最大限制为8个

    ---------------------------------------------------------------------------------------------

    `__yellow_color "3. 设置保存"`

        a. 首次运行脚本，如需保留的OpenWrt配置文件，请在OpenWrt系统/etc/sysupgrade.conf文件中添加；
           格式如下：
           ## This file contains files and directories that should
           ## be preserved during an upgrade.
           /etc/config/passwall
        b. 非首次运行脚本，请在PVE系统/etc/openwrt.upgrade文件中修改、添加；
        c. OpenWrt的备份文件，存放路径为PVE系统/root/openwrt文件夹。

    =============================================================================================
EOF
}

function linux_uname(){
    if [[ -n `uname -a | grep -i "OpenWrt"` ]]; then
        clear
        echo "`uname -a`"
        echo
        __error_msg "脚本需运行在PVE环境，检测当前为OpenWrt！"
        echo
        echo "────────────────────────────────────────────────────────────────────────────"
        echo
        echo "第1步：PVE命令行下载文件"
        __green_color "wget $Proxy_Primary/https://raw.githubusercontent.com/roacn/pve/main/openwrt.lxc.sh -O /usr/bin/openwrt && chmod +x /usr/bin/openwrt"
        echo
        echo "第2步：PVE命令行输入"
        __green_color "openwrt"
        echo
        echo "────────────────────────────────────────────────────────────────────────────"
        echo
        exit 1
    fi
}

function files_clean(){
    [[ -d $Openwrt_Path ]] && rm -rf $Openwrt_Path > /dev/null 2>&1
}


linux_uname
settings_init
network_check &

while true
do
    settings_load
    clear
    
    cat <<-EOF
`__green_color "     OpenWrt自动安装升级脚本  $Version"`
┌────────────────────────────────────────────────────┐
       1. 下载固件+更新CT模板+创建LXC容器
       2. 下载固件+更新CT模板
       3. 创建LXC容器
       4. 备份OpenWrt文件
       5. 恢复OpenWrt文件
  ──────────────────────────────────────────────────
       6. 安装依赖(curl...)
       7. 升级脚本
       8. 设置
       9. 帮助
       0. 退出
└────────────────────────────────────────────────────┘
EOF

    echo -ne "请选择: [ ]\b\b"
    read -t 120 menuid
    menuid=${menuid:-0}
    case $menuid in
    1)
        ct_update
        lxc_create
        echo
        __green_color "10s后，将清理残留文件..."
        sleep 10
        files_clean
        pause
    ;;
    2)
        ct_update
        pause
    ;;
    3)
        lxc_create
        pause
    ;;
    4)
        set_pct_id
        config_backup
        pause
    ;;
    5)
        set_pct_id
        config_recovery
        pause
    ;;
    6)
        install_tools
        pause
    ;;
    7)
        script_udpate
    ;;
    8)
        settings_modify
    ;;
    9)
        script_help
        pause
    ;;
    0)
        files_clean
        clear
        exit 0
    ;;
    *)
    ;;
    esac
done
