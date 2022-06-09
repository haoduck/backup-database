#!/bin/bash
#这个版本适用于每天备份一次

#数据库
username=root
password=123456
database=mjj

#保留n天的备份
backup_day=15

#备份目录(最后要保留斜杠,懒得多做一次判断,下面rclone的也是)
backup_dir=/root/backup/database/
[[ ! -d ${backup_dir} ]] && mkdir -p ${backup_dir} || echo -e "创建备份目录失败,请手动改创建.\n可以尝试执行 \`mkdir -p ${backup_dir}\` 试试看" && exit 1

#Rclone备份(改为'true'启用)
rclone=false
rclone_dir=onedrive:/backup/database/
delete_local=false #改为true表示rclone上传完就删除本地的


backup_file=${database}-$(date +"%Y%m%d").sql.gz
old_backup_file=${database}-$(date -d -${backup_day}day +"%Y%m%d").sql.gz
mysqldump -u${username} -p${password} ${database}|gzip > ${backup_dir}${backup_file}
if [[ $? -eq 0 ]];then
    echo "本地备份: ${backup_file}完成"
    #删除旧的数据
    if [[ -f ${old_backup_file} ]];then
        rm -f ${backup_dir}${old_backup_file} && \
        echo "删除旧备份文件: ${old_backup_file}完成"
    else
        echo "${old_backup_file}文件不存在"
    fi
    if [[ "${rclone}" == "true" ]];then
        rclone copy ${backup_dir}${backup_file} ${rclone_dir} -vP
        if [[ $? -eq 0 ]];then
            echo "rclone成功备份到: ${rclone_dir}${backup_file}"
            if [[ "${delete_local}" == "true" ]];then
                echo "rclone备份完成,删除本地备份: ${backup_dir}${backup_file}"
                rm -f ${backup_dir}${backup_file}
            fi
            #删除rclone旧的数据
            rclone delete ${rclone_dir}${old_backup_file} -vP
            if [[ $? -eq 0 ]];then
                echo "删除: ${rclone_dir}${old_backup_file}完成"
            elif [[ $? -eq 3 ]];then
                echo "${rclone_dir}${old_backup_file}文件不存在"
            fi
        else
            echo "rclone备份失败"
        fi
    fi
else
    echo "本地备份失败!"
fi
