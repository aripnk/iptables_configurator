#!/bin/bash

is_root()
{
  if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
  fi
  get_open_ports
}

get_open_ports()
{
  read -p "Please input TCP ports to open [whitespace separated]: " -a OPENED_PORTS_TCP
  read -p "Please input UDP ports to open [whitespace separated]: " -a OPENED_PORTS_UDP

  read -p "Allow ICMP (PING) packet? [Y/N] " ICMP
  case "${ICMP}" in
    Y) echo "ALL ICMP PACKET ALLOWED ..."
        ;;
    y) echo "ALL ICMP PACKET ALLOWED ..."
        ;;
    n) echo "ALL ICMP PACKET WILL BLOCKED ..."
        ;;
    N) echo "ALL ICMP PACKET WILL BLOCKED ..."
        ;;
    *) echo "Invalid input. please choose Y or N"
       echo "Operation not permitted"
       exit
  esac

  read -p "Enable syslog for blocked packets? [Y/N] " LOGGING
  case "${LOGGING}" in
    Y)  echo "LOG ENABLED ..."
        ;;
    y)  echo "LOG ENABLED ..."
        ;;
    n)  echo "LOG DISABLED ..."
        ;;
    N)  echo "LOG DISABLED ..."
        ;;
    *)  echo "Invalid input. please choose Y or N"
        echo "Operation not permitted"
        exit
  esac

  read -p "Flush all iptables rules and execute new rules? [Y/N] " EXEC
  case "${EXEC}" in
    Y)  set_open_ports
        ;;
    y)  set_open_ports
        ;;
    n)  echo "exit"
        exit
        ;;
    N)  echo "exit"
        exit
        ;;
    *) echo "Invalid input. please choose Y or N"
       echo "Operation not permitted"
       exit
  esac

}

set_open_ports()
{
  iptables -F
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT
  if [[ $ICMP == "Y" ]] || [[ $ICMP = "y" ]]; then
    allow_icmp
  fi

  for i in ${OPENED_PORTS_TCP[@]}
  do
    iptables -A INPUT -p tcp --dport $i -m state --state NEW -j ACCEPT
  done

  for j in ${OPENED_PORTS_UDP[@]}
  do
    iptables -A INPUT -p udp --dport $j -m state --state NEW -j ACCEPT
  done

  if [[ $LOGGING == "Y" ]] || [[ $LOGGING = "y" ]]; then
    iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables_INPUT_denied: " --log-level 7
  fi

  reject_all
}

reject_all()
{
  iptables -A INPUT -j REJECT
}

allow_icmp()
{
  iptables -A INPUT -p icmp -m state --state NEW --icmp-type 8 -j ACCEPT
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
}

check_conf()
{
  iptables -L
}

is_root
check_conf
