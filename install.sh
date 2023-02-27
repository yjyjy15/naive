# 等待1秒, 避免curl下载脚本的打印与脚本本身的显示冲突, 吃掉了提示用户按回车继续的信息
sleep 1

echo -e "                     _ ___                   \n ___ ___ __ __ ___ _| |  _|___ __ __   _ ___ \n|-_ |_  |  |  |-_ | _ |   |- _|  |  |_| |_  |\n|___|___|  _  |___|___|_|_|___|  _  |___|___|\n        |_____|               |_____|        "
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

error() {
    echo -e "\n$red 输入错误! $none\n"
}

pause() {
    read -rsp "$(echo -e "按 $green Enter 回车键 $none 继续....或按 $red Ctrl + C $none 取消.")" -d $'\n'
    echo
}

# 说明
echo
echo -e "$yellow此脚本仅兼容于Debian 10+系统. 如果你的系统不符合,请Ctrl+C退出脚本$none"
echo -e "可以去 ${cyan}https://github.com/crazypeace/naive${none} 查看脚本整体思路和关键命令, 以便针对你自己的系统做出调整."
echo -e "有问题加群 ${cyan}https://t.me/+ISuvkzFGZPBhMzE1${none}"
echo "本脚本支持带参数执行, 在参数中输入域名, 网络栈, 端口, 用户名, 密码. 详见GitHub."
echo "----------------------------------------------------------------"

# 执行脚本带参数
if [ $# -ge 1 ]; then
    # 默认不重新编译
    not_rebuild="Y"

    # 第1个参数是 域名
    naive_domain=${1}

    # 第2个参数是搭在ipv4还是ipv6上
    case ${2} in
    4)
        netstack=4
        ;;
    6)
        netstack=6
        ;;    
    *) # initial
        netstack="i"
        ;;    
    esac
    
    # 第3个参数是 端口
    naive_port=${3}
    if [[ -z $naive_port ]]; then
        naive_port=443
    fi
    
    #第4个参数是 用户名
    naive_user=${4}
    if [[ -z $naive_user ]]; then
        naive_user=$(openssl rand -hex 8)
    fi

    #第5个参数是 密码
    naive_pass=${5}
    if [[ -z $naive_pass ]]; then 
        # 默认与用户名相等
        naive_pass=$naive_user
    fi

    echo -e "域名: ${naive_domain}"
    echo -e "端口: ${naive_port}"
    echo -e "用户名: ${naive_user}"
    echo -e "密码: ${naive_pass}"
fi

pause

# 准备
apt update
apt install -y sudo curl wget git jq qrencode xz-utils

# 安装Caddy最新版
echo
echo -e "$yellow安装Caddy最新版本$none"
echo "----------------------------------------------------------------"
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg --yes
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

systemctl enable caddy

# 判断系统架构
case "$(uname -m)" in
    *aarch64* | *armv8*)
        SYSTEM_ARCH="arm64"
        not_rebuild="N"    #必须自己编译
        ;;
    'amd64' | 'x86_64')
        SYSTEM_ARCH="amd64"
        ;;
    *)
        SYSTEM_ARCH="$(uname -m)"
        echo -e "${red}${SYSTEM_ARCH}${none}"
        not_rebuild="N"    #必须自己编译
        ;;
esac

# 是否自己编译
if [[ -z $not_rebuild ]]; then
    echo
    echo -e "${yellow}本系统架构是${magenta}${SYSTEM_ARCH}${none}${yellow}, 你同意直接下载lxhao61编译好的Caddy吗?${none}"
    echo -e "${magenta}Y${none}, 使用编译好的Caddy; ${magenta}n${none}, 重新编译. (直接回车默认${magenta}Y${none})"
    while :; do 
        read -p "(Y/n): " not_rebuild
        [[ -z $not_rebuild ]] && not_rebuild="Y"
        case "$not_rebuild" in
            [yYnN])
                break
                ;;
            *)
                error
                ;;
        esac
    done
fi

if [[ "$not_rebuild" == [yY] ]]; then
    echo
    echo -e "$yellow下载lxhao61编译的Caddy$none"
    echo "----------------------------------------------------------------"
    cd /tmp
    rm caddy-linux-amd64.tar.gz
    rm caddy
    wget https://github.com/lxhao61/integrated-examples/releases/download/20230221/caddy-linux-amd64.tar.gz
    tar -xf caddy-linux-amd64.tar.gz
    ./caddy version
elif [[ "$not_rebuild" == [nN] ]]; then
    echo
    echo -e "$yellow自己编译NaïveProxy的Caddy$none"
    echo "----------------------------------------------------------------"
    cd /tmp
    bash <( curl -L https://github.com/crazypeace/naive/raw/main/buildcaddy.sh)
else
    error
fi

# 替换caddy可执行文件
echo
echo -e "$yellow替换Caddy可执行文件$none"
echo "----------------------------------------------------------------"
service caddy stop
cp caddy /usr/bin/

# 写个简单的html页面
mkdir -p /var/www/html
echo "hello world" > /var/www/html/index.html



# 启动NaïveProxy服务端(Caddy)
echo
echo -e "$yellow请在配置caddyfile或caddy.json后启动NaïveProxy服务端(service caddy start)$none"
echo "----------------------------------------------------------------"
# service caddy start



echo "---------- END -------------"
echo
echo "----------------------------------------------------------------"
echo "END"
