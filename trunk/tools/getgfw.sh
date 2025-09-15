#!/bin/bash

###
THIS_DIR=$ROOTDIR/user/shadowsocks
DATA_DIR=$THIS_DIR/domain-list-community-master/data
includefile="$THIS_DIR/includefile"
gfwlist="$THIS_DIR/gfwlist/gfwlist_domain.txt"
gfwfile="google facebook wikimedia twitter onedrive yahoo reddit netflix openai
         instagram twitch tumblr pinterest amazon tiktok imgur whatsapp spotify
         dailymotion threads github quora medium bbc nytimes vimeo theguardian
         rakuten slideshare deviantart telegram soundcloud xvideos"
domains="sis001.com sis001.us t66y.com"
##
rm -f $includefile
touch $includefile
#
for includeline3 in $gfwfile; do
  echo $includeline3
  sed -i '/'$includeline3'/d' $includefile && echo $includeline3 >> $includefile
  for includeline2 in $(cat $DATA_DIR/$includeline3 | grep '^include:' | awk -F: '{print $2}' | 
  sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | grep -v '\-ads$'); do
    echo $includeline2
    sed -i '/'$includeline2'/d' $includefile && echo $includeline2 >> $includefile
    for includeline1 in $(cat $DATA_DIR/$includeline2 | grep '^include:' | awk -F: '{print $2}' | 
    sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | grep -v '\-ads$'); do
      echo $includeline1
      sed -i '/'$includeline1'/d' $includefile && echo $includeline1 >> $includefile
      for includeline in $(cat $DATA_DIR/$includeline1 | grep '^include:' | awk -F: '{print $2}' | 
      sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | grep -v '\-ads$'); do
        echo $includeline
        sed -i '/'$includeline'/d' $includefile && echo $includeline >> $includefile
      done
    done
  done
done
#
rm -f $gfwlist
touch $gfwlist
#
for file in $(cat $includefile); do
  for domainline in $(cat $DATA_DIR/$file | grep -v '^#' | grep -v '^$' | grep -v '^include:' | 
  grep -v '^keyword:' | grep -v '^regexp:' | grep -v '@ads' | grep -v '@cn' | 
  sed 's/^domain://g' | sed 's/^full://g' | 
  sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | grep '\.' | 
  grep -v '\.hk$' | grep -v '\.mo$' | grep -v '\.tw$' | grep -v '\.sg$' | grep -v '\.jp$' | 
  grep -v '\.kr$' | grep -v '\.us$' | grep -v '\.uk$' | grep -v '\.de$' | grep -v '\.fr$' | 
  grep -v '\.ca$' | grep -v '\.au$' | grep -v '\.ru$' | 
  grep -v '\.xn--j6w193g$' | grep -v '\.xn--mix891f$' | grep -v '\.xn--mix082f$' | 
  grep -v '\.xn--kpry57d$' | grep -v '\.xn--kprw13d$' | grep -v '\.xn--nnx388a$' | grep -v '\.xn--yfro4i67o$' | 
  grep -v '\.xn--3e0b707e$' | grep -v '\.xn--p1ai$' | 
  grep -v 'adult' | grep -v 'porn' | grep -v 'sex' | grep -v 'fuck' | grep -v 'xxx'); do
    echo $domainline
    [ "$domainline" != "" ] && sed -i '/'$domainline'/d' $gfwlist && echo $domainline >> $gfwlist
  done
done
#
for domain in $domains; do
  echo $domain
  sed -i '/'$domain'/d' $gfwlist && echo $domain >> $gfwlist
done
#
for file in $(cat $includefile); do
  for domainline in $(cat $DATA_DIR/$file | grep -v '@ads' | grep -v '@cn' | grep '^regexp:' | 
  sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | 
  sed '/^regexp:/ s/$/:/' | sed 's/^regexp:/:/g'); do
    echo $domainline
    [ "$domainline" != "" ] && echo $domainline >> $gfwlist
  done
done
#
for file in $(cat $includefile); do
  echo $file
  [ "$file" == "google" ] && sed -i '/google/d' $gfwlist && echo ':.*google.*:' >> $gfwlist
  [ "$file" == "youtube" ] && sed -i '/^youtube/d' $gfwlist && echo ':youtube.*:' >> $gfwlist
  [ "$file" == "blogspot" ] && sed -i '/^blogspot/d' $gfwlist && echo ':blogspot\..+:' >> $gfwlist
  [ "$file" == "golang" ] && sed -r -i '/^go-lang/d' $gfwlist && echo ':go-lang\..+:' >> $gfwlist
  [ "$file" == "golang" ] && sed -r -i '/^golang/d' $gfwlist && echo ':golang\..+:' >> $gfwlist
  [ "$file" == "facebook" ] && sed -i '/facebook/d' $gfwlist && echo ':.*facebook.*:' >> $gfwlist
  [ "$file" == "twitter" ] && sed -i '/^twitter/d' $gfwlist && echo ':twitter.*:' >> $gfwlist
  [ "$file" == "onedrive" ] && sed -i '/^onedrive/d' $gfwlist && echo ':onedrive.*:' >> $gfwlist
  [ "$file" == "yahoo" ] && sed -i '/^yahoo/d' $gfwlist && echo ':yahoo.*:' >> $gfwlist
  [ "$file" == "reddit" ] && sed -i '/^reddit/d' $gfwlist && echo ':reddit.*:' >> $gfwlist
  [ "$file" == "netflix" ] && sed -i '/^netflix/d' $gfwlist && echo ':netflix.*:' >> $gfwlist
  [ "$file" == "openai" ] && sed -i '/openai/d' $gfwlist && echo ':.*openai.*:' >> $gfwlist
  [ "$file" == "instagram" ] && sed -i '/instagram/d' $gfwlist && echo ':.*instagram.*:' >> $gfwlist
  [ "$file" == "twitch" ] && sed -i '/twitch/d' $gfwlist && echo ':.*twitch.*:' >> $gfwlist
  [ "$file" == "pinterest" ] && sed -i '/^pinterest/d' $gfwlist && echo ':pinterest.*:' >> $gfwlist
  [ "$file" == "amazon" ] && sed -i '/amazon/d' $gfwlist && echo ':.*amazon.*:' >> $gfwlist
  [ "$file" == "kindle" ] && sed -i '/^kindle/d' $gfwlist && echo ':kindle.*:' >> $gfwlist
  [ "$file" == "primevideo" ] && sed -i '/^primevideo/d' $gfwlist && echo ':primevideo.*:' >> $gfwlist
  [ "$file" == "wholefoodsmarket" ] && sed -i '/^wholefoods/d' $gfwlist && echo ':wholefoods.*:' >> $gfwlist
  [ "$file" == "tiktok" ] && sed -i '/tiktok/d' $gfwlist && echo ':.*tiktok.*:' >> $gfwlist
  [ "$file" == "imgur" ] && sed -i '/^imgur/d' $gfwlist && echo ':imgur.*:' >> $gfwlist
  [ "$file" == "whatsapp" ] && sed -i '/^whatsapp/d' $gfwlist && echo ':whatsapp.*:' >> $gfwlist
  [ "$file" == "spotify" ] && sed -i '/spotify/d' $gfwlist && echo ':.*spotify.*:' >> $gfwlist
  [ "$file" == "github" ] && sed -i '/github/d' $gfwlist && echo ':.*github.*:' >> $gfwlist
  [ "$file" == "medium" ] && sed -i '/^medium\..\+/d' $gfwlist && echo ':medium\..+:' >> $gfwlist
  [ "$file" == "vimeo" ] && sed -i '/^vimeo/d' $gfwlist && echo ':vimeo.*:' >> $gfwlist
  [ "$file" == "vimeo" ] && sed -r -i '/^vhxqa[0-6]{1}\.com$/d' $gfwlist && echo ':vhxqa[0-6]{1}\.com$:' >> $gfwlist
  [ "$file" == "rakuten" ] && sed -i '/^rakuten/d' $gfwlist && echo ':rakuten.*:' >> $gfwlist
  [ "$file" == "slideshare" ] && sed -i '/^slideshare/d' $gfwlist && echo ':slideshare.*:' >> $gfwlist
  [ "$file" == "telegram" ] && sed -i '/^telegram/d' $gfwlist && echo ':telegram.*:' >> $gfwlist
done
#
echo ':.*(adult|porn|sex|fuck|xxx).*:' >> $gfwlist
#                 .新加坡        .韩国  .俄罗斯
echo ':.+\.(xn--yfro4i67o|xn--3e0b707e|xn--p1ai)$:' >> $gfwlist
#                 .香港       .澳門       .澳门       .台灣       .台湾       .臺灣
echo ':.+\.(xn--j6w193g|xn--mix891f|xn--mix082f|xn--kpry57d|xn--kprw13d|xn--nnx388a)$:' >> $gfwlist
#  香港|澳门|台湾|新加坡|日本|韩国|美国|英国|德国|法国|加拿大|澳大利亚|俄罗斯
echo ':.+\.(hk|mo|tw|sg|jp|kr|us|uk|de|fr|ca|au|ru)$:' >> $gfwlist
#
rm -f $includefile
echo "$gfwlist OK"

