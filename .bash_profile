crtsh(){
curl -s "https://crt.sh/?q=%25.$1&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | cut -d "@" -f 2 | sort -u
}

certspotter(){ 
curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | cut -d "@" -f 2 | sort -u | grep $1
}

# Give a list of domains / queries and get all the crtsh data
crtlist(){
for i in `cat $1`; do
curl -s "https://crt.sh/?q=%25.$i&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | cut -d "@" -f 2 | sort -u
done
}

# Input: live subdomains
aqua(){
cat $1 | aquatone -out aquatone
}

probe(){
cat $1 | httprobe | tee -a probed.txt
}

recon(){
subs $1; probe subs.txt; aqua probed.txt
}

fuzz() {
ffuf -c -v -w /root/tools/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -u $1/FUZZ 
}

fuzzlimit() {
ffuf -c -v -w /root/tools/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -u $1/FUZZ -rate 1
}

ds(){
python3 ~/tools/dirsearch/dirsearch.py -u $1 -e $2 -t 100 -H "X-FORWARDED-FOR: 127.0.0.1" -w /root/tools/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -x $3 --full-url
}

dslimit(){
python3 ~/tools/dirsearch/dirsearch.py -u $1 -e $2 -t 100 -H "X-FORWARDED-FOR: 127.0.0.1" -w /root/too
ls/SecLists/Discovery/Web-Content/directory-list-2.3-small.txt -x $3 --full-url -t 1 -s 1
}

# dbw hostanme php,html /root/tools/SecLists/Discovery/Web-Content/raft-large-directories.txt
dsw(){
python3 ~/tools/dirsearch/dirsearch.py -u $1 -e $2 -t 100 -H "X-FORWARDED-FOR: 127.0.0.1" -w $3 -x $4 --full-url
}

dswl(){
python3 ~/tools/dirsearch/dirsearch.py -l $1 -e $2 -t 100 -H "X-FORWARDED-FOR: 127.0.0.1" -w $3 -x $4 --full-url
}

portscan(){
sudo masscan -p1-65535 --rate=100000 --open --range $1
}

####### Larger Functions ########

# Input: domain name
subs(){
echo "Running crt.sh"
crtsh $1 > crtsh.tmp 

echo "Running subfinder"
subfinder -d $1 -o subfinder.tmp > /dev/null 2>&1

echo "Running sublist3r"
python /root/tools/Sublist3r/sublist3r.py -d $1 -o sublister.tmp > /dev/null 2>&1

echo "Running amass"
amass enum -config ~/.config/amass/config.ini -passive -d $1 -json $1.json > /dev/null 2>&1
jq .name $1.json | sed "s/\"//g" > amass.tmp
rm $1.json

echo "Running bufferover"
curl 'https://tls.bufferover.run/dns?q=.'$1 2>/dev/null | jq -r '.Results[]' 2>/dev/null | awk -F "," '{print $3}' 2>/dev/null | sort -u > bufferover.tmp 2>/dev/null

cat *.tmp | sort -u >> subs.txt
rm *.tmp
}

# Input: subdomains file
validate(){
rm /root/tools/nameservers.txt
wget https://public-dns.info/nameservers.txt -O /root/tools/nameservers/nameservers.txt
massdns -r /root/tools/nameservers/nameservers.txt -o S -w massdns.txt $1 
awk -F ". " '{print $1}' "massdns.txt" | sort -u > sub_live.txt 
grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' massdns.txt | sort -u > ips_live.txt 
rm massdns.txt
}


