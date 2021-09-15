<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#menu5_14_1#></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>

<script>
<% smartdns_status(); %>

var $j = jQuery.noConflict();

$j(document).ready(function(){
 var textArea = E('textarea');
 textArea.scrollTop = textArea.scrollHeight;
 init_itoggle('sdnse_enable');
 init_itoggle('sdnse_group');
 init_itoggle('sdnse_nra');
 init_itoggle('sdnse_nrn');
 init_itoggle('sdnse_nri');
 init_itoggle('sdnse_nsc');
 init_itoggle('sdnse_nocache');
 init_itoggle('sdnse_nrs');
 init_itoggle('sdnse_nds');
 init_itoggle('sdnse_tcp_server');
 init_itoggle('sdnse_ipv6_server');
 init_itoggle('sdnse_domain_gfw');
 init_itoggle('sdnse_port');
 init_itoggle('sdns_enable');
 init_itoggle('sdns_tcp_server');
 init_itoggle('sdns_ipv6_server');
 init_itoggle('sdns_port');
 init_itoggle('sdns_group');
 init_itoggle('sdns_redirect');
 init_itoggle('sdns_scm');
 init_itoggle('snds_dis');
 init_itoggle('snds_cache');
 init_itoggle('sdns_prefetch');
 init_itoggle('sdns_expired');
 init_itoggle('sdns_address');
 init_itoggle('sdns_logl');
 init_itoggle('sdnss_enable_x_0');
 init_itoggle('sdnss_ip_x_0');
 init_itoggle('sdnss_port_x_0');
 init_itoggle('sdnss_type_x_0');
 init_itoggle('sdnss_group_x_0');
 init_itoggle('sdnss_edg_x_0');
 init_itoggle('sdnss_ipc_x_0');
 init_itoggle('sdnss_name_x_0');
 init_itoggle('sdnss_custom_x_0');
  $j("#tab_sm_cfg, #tab_sm_cou, #tab_sm_dns, #tab_sm_sec").click(function(){
  var newHash = $j(this).attr('href').toLowerCase();
  showTab(newHash);
  return false;
  });
});

var m_list = [<% get_nvram_list("SmartdnsConf", "SdnsList"); %>];
var mlist_ifield = 7;
if(m_list.length > 0){
  var m_list_ifield = m_list[0].length;
  for (var i = 0; i < m_list.length; i++) {
  m_list[i][mlist_ifield] = i;
  }
}
function initial(){
 show_banner(2);
 show_menu(5,12,1);
 show_footer();
 showTab(getHash());
 showMRULESList();
 showmenu();
 fill_status(smartdns_status());
}

function applyRule(){
  showLoading();
  document.form.action_mode.value = " Restart ";
  document.form.current_page.value = "Advanced_smartdns.asp";
  document.form.next_page.value = "";
  document.form.submit();
}

var arrHashes = ["cfg", "cou", "dns", "sec"];

function showTab(curHash){
  var obj = $('tab_sm_'+curHash.slice(1));
  if (obj == null || obj.style.display == 'none')
  curHash = '#cfg';
  for(var i = 0; i < arrHashes.length; i++){
  if(curHash == ('#'+arrHashes[i])){
  $j('#tab_sm_'+arrHashes[i]).parents('li').addClass('active');
  $j('#wnd_sm_'+arrHashes[i]).show();
  }else{
  $j('#wnd_sm_'+arrHashes[i]).hide();
  $j('#tab_sm_'+arrHashes[i]).parents('li').removeClass('active');
  }
  }
  window.location.hash = curHash;
}

function getHash(){
  var curHash = window.location.hash.toLowerCase();
  for(var i = 0; i < arrHashes.length; i++){
  if(curHash == ('#'+arrHashes[i]))
  return curHash;
  }
  return ('#'+arrHashes[0]);
}

function fill_status(status_code){
  var stext = "Unknown";
  if (status_code == 0)
  stext = "<#Stopped#>";
  else if (status_code == 1)
  stext = "<#Running#>";
  $("smartdns_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function markGroupRULES(o, c, b) {
  document.form.group_id.value = "SdnsList";
  if(b == " Add "){
  if (document.form.sdnss_staticnum_x_0.value >= c){
  alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
  return false;
  }else if(document.form.sdnss_ip_x_0.value==""){
  alert("<#JS_fieldblank#>");
  document.form.sdnss_ip_x_0.focus();
  document.form.sdnss_ip_x_0.select();
  return false;
  }else{
  for(i=0; i<m_list.length; i++){
  if(document.form.sdnss_ip_x_0.value==m_list[i][1]) {
  if(document.form.sdnss_type_x_0.value==m_list[i][3]) {
  alert('<#JS_duplicate#>' + '(' + m_list[i][1] + ')');
  document.form.sdnss_ip_x_0.focus();
  document.form.sdnss_ip_x_0.select();
  return false;
  }
  }
  }
  }
  }
pageChanged = 0;
 document.form.action_mode.value = b;
 document.form.current_page.value = "Advanced_smartdns.asp#dns";
 return true;
}

function showmenu(){
showhide_div('dnsflink', found_app_dnsforwarder());
}

function showMRULESList(){
  var code = '<table width="100%" cellspacing="0" cellpadding="0" class="table table-list">';
  if(m_list.length == 0)
  code +='<tr><td colspan="8" style="text-align: center;"><div class="alert alert-info"><#IPConnection_VSList_Norule#></div></td></tr>';
  else{
  for(var i = 0; i < m_list.length; i++){
  if(m_list[i][0] == 0)
  sdnssenable="<#SDNS_Disable#>";
  else{
  sdnssenable="<#SDNS_Enable#>";
  }
  if(m_list[i][2] == "")
  sdnssport="<#SDNS_Default#>";
  else{
  sdnssport=m_list[i][2];
  }
  if(m_list[i][4] == "")
  sdnssgroup="<#SDNS_Default#>";
  else{
  sdnssgroup=m_list[i][4];
  }
  if(m_list[i][5] == 0)
  sdnssedg="<#SDNS_No#>";
  else{
  sdnssedg="<#SDNS_Yes#>";
  }
  if(m_list[i][6] == "blacklist")
  sdnssipc="<#BlackList#>";
  else if(m_list[i][6] == "whitelist"){
  sdnssipc="<#WhiteList#>";
  }else{
  sdnssipc="<#SDNS_Not#>";
  }
  code +='<tr id="rowrl' + i + '">';
  code +='<td colspan="1">' + sdnssenable + '</td>';
  code +='<td colspan="1">' + m_list[i][1] + '</td>';
  code +='<td colspan="1"><#SDNS_Port#>' + sdnssport + '</td>';
  code +='<td colspan="1"><#SDNS_Type#>' + m_list[i][3] + '</td>';
  code +='<td colspan="1"><#SDNS_Group#>' + sdnssgroup + '</td>';
  code +='<td colspan="1"><#SDNS_Exclude#>' + sdnssedg + '</td>';
  code +='<td colspan="1"><#SDNS_Limit#>' + sdnssipc + '</td>';
  code +='<td colspan="1" style="text-align: center;"><input type="checkbox" name="SdnsList_s" value="' + m_list[i][mlist_ifield] + '" onClick="changeBgColorrl(this,' + i + ');" id="check' + m_list[i][mlist_ifield] + '"></td>';
  code +='</tr>';
  }
  code += '<tr>';
  code += '<td colspan="7"></td>'
  code += '<td colspan="1"><button class="btn btn-danger" type="submit" onclick="markGroupRULES(this, 64, \' Del \');" name="SdnsList"><i class="icon icon-minus icon-white"></i></button></td>';
  code += '</tr>'
  }
  code +='</table>';
  $("MRULESList_Block").innerHTML = code;
}
</script>

<style>
.nav-tabs > li > a {
    padding-right: 6px;
    padding-left: 6px;
}
.spanb{
    overflow:hidden;
　　text-overflow:ellipsis;
　　white-space:nowrap;
}
</style>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div class="wrapper">
 <div class="container-fluid" style="padding-right: 0px">
  <div class="row-fluid">
   <div class="span3"><center><div id="logo"></div></center></div>
   <div class="span9" >
    <div id="TopBanner"></div>
   </div>
  </div>
 </div>

 <div id="Loading" class="popup_bg"></div>

 <iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
 <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">

 <input type="hidden" name="current_page" value="Advanced_smartdns.asp">
 <input type="hidden" name="next_page" value="">
 <input type="hidden" name="next_host" value="">
 <input type="hidden" name="sid_list" value="SmartdnsConf;">
 <input type="hidden" name="group_id" value="SdnsList">
 <input type="hidden" name="action_mode" value="">
 <input type="hidden" name="action_script" value="">
 <input type="hidden" name="sdnss_staticnum_x_0" value="<% nvram_get_x("SdnsList", "sdnss_staticnum_x"); %>" readonly="1" />

 <div class="container-fluid">
  <div class="row-fluid">
   <div class="span3">
    <!--Sidebar content-->
    <!--=====Beginning of Main Menu=====-->
    <div class="well sidebar-nav side_nav" style="padding: 0px;">
     <ul id="mainMenu" class="clearfix"></ul>
     <ul class="clearfix">
      <li>
       <div id="subMenu" class="accordion"></div>
      </li>
     </ul>
    </div>
   </div>

   <div class="span9">
    <!--Body content-->
    <div class="row-fluid">
     <div class="span12">
      <div class="box well grad_colour_dark_blue">
       <h2 class="box_head round_top"><#menu5_14#> - <#menu5_14_1#></h2>
       <div class="round_bottom">

        <div>
         <ul class="nav nav-tabs" style="margin-bottom: 10px;">
          <li class="active">
           <a id="tab_sm_cfg" href="#cfg"><#menu5_1_1#></a>
          </li>
          <li>
           <a id="tab_sm_cou" href="#cou"><#menu5_1_6#></a>
          </li>
          <li>
           <a id="tab_sm_dns" href="#dns"><#menu5_14_4#></a>
          </li>
          <li>
           <a id="tab_sm_sec" href="#sec"><#SDNS_Second_Server#></a>
          </li>
          <li id="dnsflink" style="display:none">
           <a href="dns-forwarder.asp"><#menu5_14_6#></a>
          </li>
         </ul>
        </div>

        <div class="row-fluid">
         <div id="tabMenu" class="submenuBlock"></div>
          <div class="alert alert-info" style="margin: 10px;">
           <#SDNS_Official_Website#><a href="https://pymumu.github.io/smartdns/">https://pymumu.github.io/smartdns/</a>
          </div>
         </div>

         <div id="wnd_sm_cfg">
         <table width="100%" cellpadding="0" cellspacing="0" class="table">
          <tr> <th width="50%"><#running_status#></th>
           <td id="smartdns_status" colspan="2"></td>
          </tr>

          <tr> <th><#menu5_14_5#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdns_enable_on_of">
              <input type="checkbox" id="sdns_enable_fake" <% nvram_match_x("", "sdns_enable", "1", "value=1 checked"); %><% nvram_match_x("", "sdns_enable", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdns_enable" id="sdns_enable_1" <% nvram_match_x("", "sdns_enable", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdns_enable" id="sdns_enable_0" <% nvram_match_x("", "sdns_enable", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Local_TCP_Server#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdns_tcp_server_on_of">
              <input type="checkbox" id="sdns_tcp_server_fake" <% nvram_match_x("", "sdns_tcp_server", "1", "value=1 checked"); %><% nvram_match_x("", "sdns_tcp_server", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdns_tcp_server" id="sdns_tcp_server_1" <% nvram_match_x("", "sdns_tcp_server", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdns_tcp_server" id="sdns_tcp_server_0" <% nvram_match_x("", "sdns_tcp_server", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Local_IPv6_Server#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdns_ipv6_server_on_of">
              <input type="checkbox" id="sdns_ipv6_server_fake" <% nvram_match_x("", "sdns_ipv6_server", "1", "value=1 checked"); %><% nvram_match_x("", "sdns_ipv6_server", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdns_ipv6_server" id="sdns_ipv6_server_1" <% nvram_match_x("", "sdns_ipv6_server", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdns_ipv6_server" id="sdns_ipv6_server_0" <% nvram_match_x("", "sdns_ipv6_server", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Local_Port#></th>
           <td>
            <input type="text" maxlength="5" class="input" size="5" name="sdns_port" style="width: 134px" placeholder="5353" value="<% nvram_get_x("", "sdns_port"); %>"> [1..65535]
           </td>
          </tr>

          <tr> <th><#SDNS_Redirect#></th>
           <td>
            <select name="sdns_redirect" class="input" style="width: 217px">
             <option value="0" <% nvram_match_x("","sdns_redirect", "0","selected"); %>><#SDNS_Not#></option>
             <option value="1" <% nvram_match_x("","sdns_redirect", "1","selected"); %>><#SDNS_Dnsmasq_Upserver#></option>
             <option value="2" <% nvram_match_x("","sdns_redirect", "2","selected"); %>><#SDNS_Main_Server#></option>
            </select>
           </td>
          </tr>

          <tr> <th><#SDNS_Speed_Check_Mode#></th>
           <td>
            <select name="sdns_scm" class="input" style="width: 217px">
             <option value="0" <% nvram_match_x("","sdns_scm", "0","selected"); %>><#SDNS_Not#></option>
             <option value="1" <% nvram_match_x("","sdns_scm", "1","selected"); %>><#SDNS_ping_tcp80#></option>
             <option value="2" <% nvram_match_x("","sdns_scm", "2","selected"); %>><#SDNS_ping_tcp443#></option>
             <option value="3" <% nvram_match_x("","sdns_scm", "3","selected"); %>><#SDNS_tcp80_ping#></option>
             <option value="4" <% nvram_match_x("","sdns_scm", "4","selected"); %>><#SDNS_tcp443_ping#></option>
             <option value="5" <% nvram_match_x("","sdns_scm", "5","selected"); %>><#SDNS_tcp80_tcp443#></option>
             <option value="6" <% nvram_match_x("","sdns_scm", "6","selected"); %>><#SDNS_tcp443_tcp80#></option>
            </select>
           </td>
          </tr>

          <tr> <th><#SDNS_Dualstack_Selection#></th>
           <td>
            <div class="main_itoggle">
             <div id="snds_dis_on_of">
              <input type="checkbox" id="snds_dis_fake" <% nvram_match_x("", "snds_dis", "1", "value=1 checked"); %><% nvram_match_x("", "snds_dis", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="0" name="snds_dis" id="snds_dis_0" <% nvram_match_x("", "snds_dis", "0", "checked"); %>><#checkbox_No#>
             <input type="radio" value="1" name="snds_dis" id="snds_dis_1" <% nvram_match_x("", "snds_dis", "1", "checked"); %>><#checkbox_Yes#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Address#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdns_address_on_of">
              <input type="checkbox" id="sdns_address_fake" <% nvram_match_x("", "sdns_address", "1", "value=1 checked"); %><% nvram_match_x("", "sdns_address", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="0" name="sdns_address" id="sdns_address_0" <% nvram_match_x("", "sdns_address", "0", "checked"); %>><#checkbox_No#>
             <input type="radio" value="1" name="sdns_address" id="sdns_address_1" <% nvram_match_x("", "sdns_address", "1", "checked"); %>><#checkbox_Yes#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Cache_Size#></th>
           <td>
            <input type="text" maxlength="4" class="input" size="4" name="snds_cache" style="width: 134px" placeholder="<#Config_0_Disable#>" value="<% nvram_get_x("", "snds_cache"); %>"> [0..4096]
           </td>
          </tr>

          <tr> <th><#SDNS_Domain_Prefetch#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdns_prefetch_on_of">
              <input type="checkbox" id="sdns_prefetch_fake" <% nvram_match_x("", "sdns_prefetch", "1", "value=1 checked"); %><% nvram_match_x("", "sdns_prefetch", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="0" name="sdns_prefetch" id="sdns_prefetch_0" <% nvram_match_x("", "sdns_prefetch", "0", "checked"); %>><#checkbox_No#>
             <input type="radio" value="1" name="sdns_prefetch" id="sdns_prefetch_1" <% nvram_match_x("", "sdns_prefetch", "1", "checked"); %>><#checkbox_Yes#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Serve_Expired#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdns_expired_on_of">
              <input type="checkbox" id="sdns_expired_fake" <% nvram_match_x("", "sdns_expired", "1", "value=1 checked"); %><% nvram_match_x("", "sdns_expired", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="0" name="sdns_expired" id="sdns_expired_0" <% nvram_match_x("", "sdns_expired", "0", "checked"); %>><#checkbox_No#>
             <input type="radio" value="1" name="sdns_expired" id="sdns_expired_1" <% nvram_match_x("", "sdns_expired", "1", "checked"); %>><#checkbox_Yes#>
            </div>
           </td>
          </tr>
         </table>
         </div>


         <div id="wnd_sm_cou">
         <table width="100%" cellpadding="0" cellspacing="0" class="table">
          <tr> <th colspan="2" style="background-color: #E3E3E3;"><#SDNS_Custom_Settings#></th></tr>

          <tr>
           <td colspan="2" style="border-top: 0 none; padding-bottom: 0px;">
            <textarea rows="8" wrap="off" spellcheck="false" class="span12" name="scripts.smartdns_custom.conf" style="font-family:'Courier New', Courier, mono; font-size:13px;"><% nvram_dump("scripts.smartdns_custom.conf",""); %></textarea>
           </td>
          </tr>

          <tr> <th width="50%"><#SDNS_Domains_Whitelist#></th>
           <td>
            <input type="text" maxlength="32" class="input" size="32" name="sdns_group" placeholder="<#SDNS_Server_Group#> <#Config_No_Empty#> [CHN]" style="width: 217px" value="<% nvram_get_x("", "sdns_group"); %>">
           </td>
          </tr>

          <tr>
           <td colspan="2" style="border-top: 0 none; padding-bottom: 0px;">
            <textarea rows="8" wrap="off" spellcheck="false" class="span12" name="scripts.smartdns_whitelist.conf" style="font-family:'Courier New', Courier, mono; font-size:13px;"><% nvram_dump("scripts.smartdns_whitelist.conf",""); %></textarea>
           </td>
          </tr>

          <tr> <th width="50%"><#SDNS_Domains_Blacklist#></th>
           <td>
            <input type="text" maxlength="32" class="input" size="32" name="sdnse_group" placeholder="<#SDNS_Server_Group#> <#Config_No_Empty#> [GFW]" style="width: 217px" value="<% nvram_get_x("", "sdnse_group"); %>">
           </td>
          </tr>

          <tr>
           <td colspan="2" style="border-top: 0 none; padding-bottom: 0px;">
            <textarea rows="8" wrap="off" spellcheck="false" class="span12" name="scripts.smartdns_blacklist.conf" style="font-family:'Courier New', Courier, mono; font-size:13px;"><% nvram_dump("scripts.smartdns_blacklist.conf",""); %></textarea>
           </td>
          </tr>

          <tr> <th width="50%"><#menu5_13_log#></th>
           <td>
            <input type="text" maxlength="6" class="input" size="6" name="sdns_logl" placeholder="[fatal|error|warn|notice|info|debug]" style="width: 217px" value="<% nvram_get_x("", "sdns_logl"); %>">
           </td>
          </tr>

          <tr>
           <td colspan="2" style="border-top: 0 none; padding-bottom: 0px;">
             <textarea rows="8" class="span12" style="font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("smartdns.log",""); %></textarea>
           </td>
          </tr>
         </table>
         </div>


         <div id="wnd_sm_dns">
         <table width="100%" cellpadding="0" cellspacing="0" class="table">
         <tbody>
          <tr> <th width="50%"><#SDNS_Enable_Upstream_Server#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnss_enable_x_0_on_of">
              <input type="checkbox" id="sdnss_enable_x_0_fake" <% nvram_match_x("", "sdnss_enable_x_0", "1", "value=1 checked"); %><% nvram_match_x("", "sdnss_enable_x_0", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnss_enable_x_0" id="sdnss_enable_x_0_1" <% nvram_match_x("", "sdnss_enable_x_0", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnss_enable_x_0" id="sdnss_enable_x_0_0" <% nvram_match_x("", "sdnss_enable_x_0", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Upstream_Server_IP#></th>
           <td>
            <input type="text" maxlength="64" class="span12" style="width: 217px" size="64" name="sdnss_ip_x_0" placeholder="[8.8.8.8|https://8.8.8.8/dns-query]" value="<% nvram_get_x("", "sdnss_ip_x_0"); %>" onKeyPress="return is_string(this,event);"/>
           </td>
          </tr>

          <tr> <th><#SDNS_Upstream_Server_Port#></th>
           <td>
            <input type="text" maxlength="8" class="span12" style="width: 217px" size="8" name="sdnss_port_x_0" placeholder="<#Config_Empty_Default#> [53|853|443]" value="<% nvram_get_x("", "sdnss_port_x_0"); %>" onKeyPress="return is_string(this,event);"/>
           </td>
          </tr>

          <tr> <th><#SDNS_Upstream_Server_Type#></th>
           <td>
            <select name="sdnss_type_x_0" class="input" style="width: 134px">
             <option value="tls" <% nvram_match_x("","sdnss_type_x_0", "0","selected"); %>>tls</option>
             <option value="tcp" <% nvram_match_x("","sdnss_type_x_0", "tcp","selected"); %>>tcp</option>
             <option value="udp" <% nvram_match_x("","sdnss_type_x_0", "udp","selected"); %>>udp</option>
             <option value="https" <% nvram_match_x("","sdnss_type_x_0", "https","selected"); %>>https</option>
            </select>
           </td>
          </tr>

          <tr> <th><#SDNS_Upstream_Server_Group#></th>
           <td>
            <input type="text" maxlength="32" class="span12" style="width: 217px" size="32" name="sdnss_group_x_0" placeholder="<#Config_Empty_Default#> [CHN|GFW]" value="<% nvram_get_x("", "sdnss_group_x_0"); %>" onKeyPress="return is_string(this,event);"/>
           </td>
          </tr>

          <tr> <th><#SDNS_Exclude_Default_Group#></th>
           <td>
            <select name="sdnss_edg_x_0" class="input" style="width: 134px">
             <option value="0" <% nvram_match_x("","sdnss_edg_x_0", "0","selected"); %>><#SDNS_No#></option>
             <option value="1" <% nvram_match_x("","sdnss_edg_x_0", "1","selected"); %>><#SDNS_Yes#></option>
            </select>
           </td>
          </tr>

          <tr> <th><#SDNS_ChnRoute_Limit#></th>
           <td>
            <select name="sdnss_ipc_x_0" class="input" style="width: 134px">
             <option value="0" <% nvram_match_x("","sdnss_ipc_x_0", "0","selected"); %>><#SDNS_Disable_Unlimited#></option>
             <option value="whitelist" <% nvram_match_x("","sdnss_ipc_x_0", "whitelist","selected"); %>><#SDNS_Chn_Whitelist#></option>
             <option value="blacklist" <% nvram_match_x("","sdnss_ipc_x_0", "blacklist","selected"); %>><#SDNS_Overseas_Blacklist#></option>
            </select>
           </td>
          </tr>

          <tr> <th><#SDNS_Cert_Hostname_Verify#></th>
           <td>
            <input type="text" maxlength="32" class="span12" style="width: 217px" size="32" name="sdnss_name_x_0" placeholder="<#Config_Empty_Disable#> [dns.google]" value="<% nvram_get_x("", "sdnss_name_x_0"); %>" onKeyPress="return is_string(this,event);"/>
           </td>
          </tr>

          <tr> <th><#SDNS_Custom_Set_Args#></th>
           <td>
            <input type="text" maxlength="64" class="span12" style="width: 217px" size="64" name="sdnss_custom_x_0" placeholder="<#Config_Empty_Disable#> [-no-check-certificate]" value="<% nvram_get_x("", "sdnss_custom_x_0"); %>" onKeyPress="return is_string(this,event);"/>
           </td>
          </tr>
         </tbody>
         </table>

         <table width="100%" align="center" cellpadding="0" cellspacing="0" class="table">
          <tr>
           <td><center><input name="ManualRULESList2" type="submit" class="btn btn-primary" style="width: 217px" onclick="return markGroupRULES(this, 64, ' Add ');" value="<#SDNS_Save_Upstream_Server#>"/></center></td>          
          </tr>
         </table>

         <table width="100%" align="center" cellpadding="0" cellspacing="0" class="table">
          <tr id="row_rules_body" >
           <td colspan="8" style="border-top: 0 none; padding: 0px;">
            <div id="MRULESList_Block"></div>
           </td>
          </tr>
         </table>
         </div>


         <div id="wnd_sm_sec">
         <table width="100%" cellpadding="0" cellspacing="0" class="table">
          <tr> <th width="50%"><#SDNS_Enable_Second_Server#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_enable_on_of">
              <input type="checkbox" id="sdnse_enable_fake" <% nvram_match_x("", "sdnse_enable", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_enable", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_enable" id="sdnse_enable_1" <% nvram_match_x("", "sdnse_enable", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_enable" id="sdnse_enable_0" <% nvram_match_x("", "sdnse_enable", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Local_TCP_Server#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_tcp_server_on_of">
              <input type="checkbox" id="sdnse_tcp_server_fake" <% nvram_match_x("", "sdnse_tcp_server", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_tcp_server", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_tcp_server" id="sdnse_tcp_server_1" <% nvram_match_x("", "sdnse_tcp_server", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_tcp_server" id="sdnse_tcp_server_0" <% nvram_match_x("", "sdnse_tcp_server", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Local_IPv6_Server#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_ipv6_server_on_of">
              <input type="checkbox" id="sdnse_ipv6_server_fake" <% nvram_match_x("", "sdnse_ipv6_server", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_ipv6_server", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_ipv6_server" id="sdnse_ipv6_server_1" <% nvram_match_x("", "sdnse_ipv6_server", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_ipv6_server" id="sdnse_ipv6_server_0" <% nvram_match_x("", "sdnse_ipv6_server", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Local_Port#></th>
           <td>
            <input type="text" maxlength="5" class="input" size="5" name="sdnse_port" placeholder="60" style="width: 83px" value="<% nvram_get_x("", "sdnse_port"); %>">
           </td>
          </tr>

          <tr> <th><#SDNS_Domains_Blacklist_Resolve#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_domain_gfw_on_of">
              <input type="checkbox" id="sdnse_domain_gfw_fake" <% nvram_match_x("", "sdnse_domain_gfw", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_domain_gfw", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_domain_gfw" id="sdnse_domain_gfw_1" <% nvram_match_x("", "sdnse_domain_gfw", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_domain_gfw" id="sdnse_domain_gfw_0" <% nvram_match_x("", "sdnse_domain_gfw", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_Speed_Check#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nsc_on_of">
              <input type="checkbox" id="sdnse_nsc_fake" <% nvram_match_x("", "sdnse_nsc", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nsc", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nsc" id="sdnse_nsc_1" <% nvram_match_x("", "sdnse_nsc", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nsc" id="sdnse_nsc_0" <% nvram_match_x("", "sdnse_nsc", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_Dualstack_Selection#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nds_on_of">
              <input type="checkbox" id="sdnse_nds_fake" <% nvram_match_x("", "sdnse_nds", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nds", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nds" id="sdnse_nds_1" <% nvram_match_x("", "sdnse_nds", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nds" id="sdnse_nds_0" <% nvram_match_x("", "sdnse_nds", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_Cache#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nocache_on_of">
              <input type="checkbox" id="sdnse_nocache_fake" <% nvram_match_x("", "sdnse_nocache", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nocache", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nocache" id="sdnse_nocache_1" <% nvram_match_x("", "sdnse_nocache", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nocache" id="sdnse_nocache_0" <% nvram_match_x("", "sdnse_nocache", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_Nameserver_Rules#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nrn_on_of">
              <input type="checkbox" id="sdnse_nrn_fake" <% nvram_match_x("", "sdnse_nrn", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nrn", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nrn" id="sdnse_nrn_1" <% nvram_match_x("", "sdnse_nrn", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nrn" id="sdnse_nrn_0" <% nvram_match_x("", "sdnse_nrn", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_Ipset_Rules#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nri_on_of">
              <input type="checkbox" id="sdnse_nri_fake" <% nvram_match_x("", "sdnse_nri", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nri", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nri" id="sdnse_nri_1" <% nvram_match_x("", "sdnse_nri", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nri" id="sdnse_nri_0" <% nvram_match_x("", "sdnse_nri", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_Address_Rules#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nra_on_of">
              <input type="checkbox" id="sdnse_nra_fake" <% nvram_match_x("", "sdnse_nra", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nra", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nra" id="sdnse_nra_1" <% nvram_match_x("", "sdnse_nra", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nra" id="sdnse_nra_0" <% nvram_match_x("", "sdnse_nra", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>

          <tr> <th><#SDNS_Skip_SOA_Address_Rules#></th>
           <td>
            <div class="main_itoggle">
             <div id="sdnse_nrs_on_of">
              <input type="checkbox" id="sdnse_nrs_fake" <% nvram_match_x("", "sdnse_nrs", "1", "value=1 checked"); %><% nvram_match_x("", "sdnse_nrs", "0", "value=0"); %>>
             </div>
            </div>
            <div style="position: absolute; margin-left: -10000px;">
             <input type="radio" value="1" name="sdnse_nrs" id="sdnse_nrs_1" <% nvram_match_x("", "sdnse_nrs", "1", "checked"); %>><#checkbox_Yes#>
             <input type="radio" value="0" name="sdnse_nrs" id="sdnse_nrs_0" <% nvram_match_x("", "sdnse_nrs", "0", "checked"); %>><#checkbox_No#>
            </div>
           </td>
          </tr>
         </table>
         </div>


         <table class="table">         
          <tr>
           <td colspan="2">
            <center><input class="btn btn-primary" style="width: 217px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
           </td>
          </tr>
         </table>
        </div>
       </div>
      </div>
     </div>
    </div>
   </div>
  </div>
 </div>
</form>
<div id="footer"></div>
</div>

</body>
</html>
