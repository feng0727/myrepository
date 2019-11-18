#!/usr/bin/expect
#author by yangfei
#create 2017-11-17
set select [lindex $argv 0]
set username [lindex $argv 1]
set password [lindex $argv 2]
set branchOrTag [lindex $argv 3]
switch $select {
"code" {
#push code
spawn git push origin HEAD:refs/heads/$branchOrTag
expect "Username for 'https://git.uyunsoft.cn':"
send "$username\r"
expect "Password for 'https://$username@git.uyunsoft.cn':"
send "$password\r"
}
"deltag" {
#push tag
# delete exists tag
spawn git push origin :refs/tags/${branchOrTag}
expect "Username for 'https://git.uyunsoft.cn':"
send "$username\r"
expect "Password for 'https://$username@git.uyunsoft.cn':"
send "$password\r"
}
"tag" {
#push tag
spawn git push origin $branchOrTag
expect "Username for 'https://git.uyunsoft.cn':"
send "$username\r"
expect "Password for 'https://$username@git.uyunsoft.cn':"
send "$password\r"
}
default {
  puts "nothing"
}
}
expect eof