#!/bin/bash

###
THIS_DIR=$ROOTDIR/user/shadowsocks
DATA_DIR=$THIS_DIR/domain-list-community-master/data
includefile="$THIS_DIR/includefile"
chnlist="$THIS_DIR/chnlist/chnlist_domain.txt"
chnfile="alibaba baidu bytedance tencent bing bilibili"
domains="world.taobao.com"
##
rm -f $includefile
touch $includefile
#
for includeline3 in $chnfile; do
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
rm -f $chnlist
touch $chnlist
#
for file in $(cat $includefile); do
  for domainline in $(cat $DATA_DIR/$file | grep -v '^#' | grep -v '^$' | grep -v '^include:' | 
  grep -v '^keyword:' | grep -v '^regexp:' | grep -v '@ads' | grep -v '@!cn' | 
  sed 's/^domain://g' | sed 's/^full://g' | 
  sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | grep '\.' | 
  grep -v '\.cn$' | grep -v '\.xn--fiqs8s$' | grep -v '\.xn--fiqz9s$' | grep -v '\.xn--zfr164b$' | 
  grep -v '\.xn--55qw42g$' | grep -v '\.xn--55qx5d$' | grep -v '\.xn--3bst00m$' | grep -v '\.xn--vhquv$' | 
  grep -v '\.xn--6frz82g$' | grep -v '\.xn--8y0a063a$' | grep -v '\.xn--estv75g$' | grep -v '\.xn--fiq64b$' | 
  grep -v '\.xn--czr694b$' | grep -v '\.xn--czru2d$' | grep -v '\.xn--czrs0t$' | 
  grep -v '\.xn--io0a7i$' | grep -v '\.xn--ses554g$' | grep -v '\.xn--hxt814e$' | 
  grep -v '\.xn--5tzm5g$' | grep -v '\.xn--fiq228c5hs$' | grep -v '\.xn--6qq986b3xl$' | 
  grep -v '\.xn--kput3i$' | grep -v '\.xn--3ds443g$' | grep -v '\.xn--vuq861b$' | grep -v '\.xn--fjq720a$' | 
  grep -v '\.xn--unup4y$' | grep -v '\.xn--g2xx48c$' | grep -v '\.xn--imr513n$' | 
  grep -v '\.xn--9et52u$' | grep -v '\.xn--nyqy26a$' | grep -v '\.xn--otu796d$'); do
    echo $domainline
    [ "$domainline" != "" ] && sed -i '/'$domainline'/d' $chnlist && echo $domainline >> $chnlist
  done
done
#
for domain in $domains; do
  echo $domain
  sed -i '/'$domain'/d' $chnlist && echo $domain >> $chnlist
done
#
for file in $(cat $includefile); do
  for domainline in $(cat $DATA_DIR/$file | grep -v '@ads' | grep -v '@!cn' | grep '^regexp:' | 
  sed 's/[[:space:]]//g' | sed 's/@.*$//g' | sed 's/#.*$//g' | 
  sed '/^regexp:/ s/$/:/' | sed 's/^regexp:/:/g'); do
    echo $domainline
    [ "$domainline" != "" ] && sed -i '/'$domainline'/d' $chnlist && echo $domainline >> $chnlist
  done
done
#
for file in $(cat $includefile); do
  echo $file
  [ "$file" == "alibaba" ] && sed -i '/^alibaba/d' $chnlist && echo ':alibaba.*:' >> $chnlist
  [ "$file" == "aliyun" ] && sed -i '/alicdn/d' $chnlist && echo ':.*alicdn.*:' >> $chnlist
  [ "$file" == "aliyun" ] && sed -i '/aliyun/d' $chnlist && echo ':.*aliyun.*:' >> $chnlist
  [ "$file" == "aliyun" ] && sed -i '/kunlun/d' $chnlist && echo ':.*kunlun.*:' >> $chnlist
  [ "$file" == "baidu" ] && sed -i '/^duxiaoman/d' $chnlist && echo ':duxiaoman.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/^bytedance/d' $chnlist && echo ':bytedance.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/^bytedns/d' $chnlist && echo ':bytedns.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/byteimg\.com$/d' $chnlist && echo ':.*byteimg\.com$:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/huoshan/d' $chnlist && echo ':.*huoshan.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/douyin/d' $chnlist && echo ':.*douyin.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/^toutiao/d' $chnlist && echo ':toutiao.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/^vestack-/d' $chnlist && echo ':vestack-.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/xigua/d' $chnlist && echo ':.*xigua.*:' >> $chnlist
  [ "$file" == "bytedance" ] && sed -i '/^zijie/d' $chnlist && echo ':zijie.*:' >> $chnlist
  [ "$file" == "volcengine" ] && sed -i '/^fanqie/d' $chnlist && echo ':fanqie.*:' >> $chnlist
  [ "$file" == "volcengine" ] && sed -i '/^fqnovel/d' $chnlist && echo ':fqnovel.*:' >> $chnlist
  [ "$file" == "volcengine" ] && sed -i '/^volc/d' $chnlist && echo ':volc.*:' >> $chnlist
  [ "$file" == "tencent" ] && sed -i '/tencent/d' $chnlist && echo ':.*tencent.*:' >> $chnlist
  [ "$file" == "tencent" ] && sed -i '/^fyeds/d' $chnlist && echo ':fyeds.*:' >> $chnlist
  [ "$file" == "tencent" ] && sed -i '/^fymall/d' $chnlist && echo ':fymall.*:' >> $chnlist
  [ "$file" == "bing" ] && sed -i '/bing/d' $chnlist && echo ':.*bing.*:' >> $chnlist
done
#                 .世界       .广东       .佛山
echo ':.+\.(xn--rhqv96g|xn--xhq521b|xn--1qqw23a)$:' >> $chnlist
#                .手机       .在线       .信息       .娱乐      .游戏       .购物       .餐厅      .时尚       .健康       .招聘
echo ':.+\.(xn--kput3i|xn--3ds443g|xn--vuq861b|xn--fjq720a|xn--unup4y|xn--g2xx48c|xn--imr513n|xn--9et52u|xn--nyqy26a|xn--otu796d)$:' >> $chnlist
#                .网络       .网址       .网店      .网站        .中文网        .我爱你
echo ':.+\.(xn--io0a7i|xn--ses554g|xn--hxt814e|xn--5tzm5g|xn--fiq228c5hs|xn--6qq986b3xl)$:' >> $chnlist
#                 .移动        .联通       .工行      .中信       .商标      .商城      .商店
echo ':.+\.(xn--6frz82g|xn--8y0a063a|xn--estv75g|xn--fiq64b|xn--czr694b|xn--czru2d|xn--czrs0t)$:' >> $chnlist
#          .cn      .中国      .中國       .政务       .公益      .公司       .集团     .企业
echo ':.+\.(cn|xn--fiqs8s|xn--fiqz9s|xn--zfr164b|xn--55qw42g|xn--55qx5d|xn--3bst00m|xn--vhquv)$:' >> $chnlist
#
rm -f $includefile
echo "$chnlist OK"

