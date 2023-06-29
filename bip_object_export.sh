ERP_USERNAME=${1}
ERP_PASSWORD=${2}
BIP_URL=${3}
BITBUCKET_EMAIL=${4}
BRANCH_NAME=${5}
INTEGRATION_PWD=${6}
BITBUCKET_USERNAME=${7}
COMMIT_COMMENT=${8}
#Credential Check
echo $BIP_URL
STR2=$(echo $BIP_URL | cut -d'/' -f 3)
echo $STR2
curl -i -u $SOURCE_ERP_USERNAME:$SOURCE_ERP_PASSWORD -X GET https://$STR2/hcmRestApi/resources/11.13.18.05/emps/1 2>&1 | tee curl_output
 
if grep -q '404 Not Found' "curl_output"
then
    echo "Test Passed"
else
echo "Invalid Username or Password"
    exit 1
fi
#Credential Check
 
BIP_CONFIG_LOCATION=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/bip_config.json
BIP_CONFIG_DIR=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config
BIP_CATALOG_DIR=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip
ls -latr $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log
# start report changes
RESULT_OUTPUT=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/EXPORT_Report_to_GIT/"$BUILD_NUMBER".out  
CI_REPORT=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/EXPORT_Report_to_GIT/"$BUILD_NUMBER".html
total_bi_objects=0
total_passed=0
total_failed=0
 
BIP_HOST=$(echo $BIP_URL | cut -d'/' -f 3)
echo $BIP_HOST
BIP_HOST_URL="https://$BIP_HOST"
echo $BIP_HOST_URL
SESSION_ID=''
 
# end report changes
 
export BIP_CATALOG_UTIL_DIR=$WORKSPACE/utils/utils/bip_cicd
export BIP_LIB_DIR=$WORKSPACE/utils/utils/bip_cicd/lib
export BIP_CLIENT_CONFIG=$WORKSPACE/utils/utils/bip_cicd/config
 
GIT_LOG=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/push_to_repository.log
chmod -R 777 $BIP_CATALOG_UTIL_DIR/bin
 
cp $WORKSPACE/utils/utils/bip_cicd/config/xmlp-client-config.xml $WORKSPACE/utils/utils/bip_cicd/xmlp-client-config.xml
sed -i "s/{{password}}/$ERP_PASSWORD/g" $WORKSPACE/utils/utils/bip_cicd/config/xmlp-client-config.xml
sed -i "s/{{userid}}/$ERP_USERNAME/g" $WORKSPACE/utils/utils/bip_cicd/config/xmlp-client-config.xml
sed -i "s,{{bipuri}},$BIP_URL,g" $WORKSPACE/utils/utils/bip_cicd/config/xmlp-client-config.xml
 
 
 # start report changes
function log_result () {
   operation=$1
   object_type=$2
   object_path=$3
   check_file=$4
 
   # Check for HTTP return code 
 
    if [[ "$object_type" == "xdo" ]]; then
        if grep -q '<getObjectReturn>' $check_file; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Passed" 2>&1 |& tee -a $RESULT_OUTPUT
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Failed" 2>&1 |& tee -a $RESULT_OUTPUT
        fi
    elif [[ "$object_type" == "xdm" ]]; then
        if grep -q '<getObjectReturn>' $check_file; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Passed" 2>&1 |& tee -a $RESULT_OUTPUT
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Failed" 2>&1 |& tee -a $RESULT_OUTPUT
        fi
    else
        if grep -q 'Archive Not Found' $check_file;then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Failed" 2>&1 |& tee -a $RESULT_OUTPUT
        elif grep -q 'Start of root element' $check_file;then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Failed" 2>&1 |& tee -a $RESULT_OUTPUT
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')]|$operation|$object_type|$object_path|Passed" 2>&1 |& tee -a $RESULT_OUTPUT
        fi
    fi
 
}
 
function ciout_to_html () {
    html=$CI_REPORT
    input_file=$1
    total_num=$2
    pass=$3
    failed=$4
 
    echo "total BI objects: $total_num"
    echo "pass: $pass"
    echo "failed: $failed"
 
    echo "<html>" >> $html
    echo "  <style>
            table {
                border-collapse: collapse;
                width: 80%;
            }
            th {
                border: 1px solid #ccc;
                padding: 5px;
                text-align: left;
                font-size: "16";
            }
            td {
                border: 1px solid #ccc;
                padding: 5px;
                text-align: left;
                font-size: "14";
            }
            tr:nth-child(even) {
                background-color: #eee;
            }
            tr:nth-child(odd) {
                background-color: #fff;
            }
    </style>" >> $html
 
    echo "<body>" >> $html
    echo "</br>" >> $html
    echo "<b><u><font face="Verdana" size='3' color='#033AOF'>Export BI Report Objects Summary Report</font></u></b>" >> $html
    echo "</br></br>" >> $html
    echo "<b><font face="Verdana" size='2' color='#5F3306'>BIP URL: </font></b>" >> $html
    echo "<font face="Verdana" size='2' color='#2211CF'>$BIP_URL</font>" >> $html
    echo "</br></br>" >> $html
    echo "<font size='3'>Total BI Report Objects = </font>" >> $html
    echo "<font size='3'><b>$total_num</b></font>" >> $html
    echo "</br>" >> $html
    echo "<font size='3' color='blue'>Passed = </font>" >> $html
    echo "<font size='3' color='blue'>$pass</font>" >> $html
    echo "</br>" >> $html
    if [ $failed -gt 0 ]
    then
        echo "<font size='3' color='red'><b>Failed = </b></font>" >> $html
        echo "<font size='3' color='red'><b>$failed</b></font>" >> $html
        echo "</br>" >> $html
    fi
    echo "</br>" >> $html
    echo "<table>" >> $html
    echo "<th>Timestamp</th>" >> $html
    echo "<th>Operation</th>" >> $html
    echo "<th>Object Type/Code</th>" >> $html
    echo "<th>Object Full Path</th>" >> $html
    echo "<th>Status</th>" >> $html
 
    while IFS='|' read -ra line ; do
        echo "<tr>" >> $html
        for i in "${line[@]}"; do
           echo "<td>$i</td>"
           if echo $i| grep -iqF Pass; then
                echo " <td><font color="blue">$i</font></td>" >> $html
           elif echo $i | grep -iqF Fail; then
                echo " <td><font color="red">$i</font></td>" >> $html
           else
                echo " <td>$i</td>" >> $html
           fi
        done
        echo "</tr>"
        echo "</tr>" >> $html
    done < $input_file
 
    echo "</table>" >> $html
 
    echo "</body>" >> $html
    echo "</html>" >> $html
 
}
 
function get_sessionId () {
    echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:v12=\"urn://oracle.bi.webservices/v12\">" > $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml 
    echo "<soapenv:Header/><soapenv:Body><v12:logon>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml 
    echo "<v12:name>$ERP_USERNAME</v12:name>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml 
    echo "<v12:password>$ERP_PASSWORD</v12:password>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml 
    echo "</v12:logon></soapenv:Body></soapenv:Envelope>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml
 
    curl --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:logon" --data @$WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml "$BIP_HOST_URL/analytics-ws/saw.dll?SoapImpl=nQSessionService" | xmllint --format - > $WORKSPACE/utils/utils/bip_cicd/bin/loginResponse.xml
 
    SESSION_ID=$(xmllint --xpath "//*[local-name()='sessionID']/text()" $WORKSPACE/utils/utils/bip_cicd/bin/loginResponse.xml)
    echo $SESSION_ID
}
 
function export_report_object(){
    FILE_PATH="$1"
 
    echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:v12=\"urn://oracle.bi.webservices/v12\">" > $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
    echo "<soapenv:Header/><soapenv:Body><v12:copyItem2>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
    echo "<v12:path>$FILE_PATH</v12:path>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
    echo "<v12:recursive>true</v12:recursive><v12:permissions>false</v12:permissions><v12:timestamps>false</v12:timestamps><v12:useMtom>false</v12:useMtom>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
    echo "<v12:sessionID>$SESSION_ID</v12:sessionID>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
    echo "</v12:copyItem2></soapenv:Body></soapenv:Envelope>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
 
    #cat $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
 
    curl --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:copyItem2" --data @$WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml $BIP_HOST_URL/analytics-ws/saw.dll?SoapImpl=webCatalogService | xmllint --format - > $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml
    xmllint --xpath "//*[local-name()='archive']/text()" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml > $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt
 
    SOURCE_FOLDER=$(echo ${FILE_PATH:7})   
	ZIPPED_FILE="$SOURCE_FOLDER"z
	if [[ "${FILE_PATH##*.}" == "xdo" ]]; then
        echo "The file is an .xdo file"
		cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt | base64 -d > "$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/source_files$ZIPPED_FILE"
    elif [[ "${FILE_PATH##*.}" == "xdm" ]]; then
        echo "The file is an .xdm file"
		cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt | base64 -d > "$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/source_files$ZIPPED_FILE"
    else
        echo "The file is a catalog file"
		SOURCE_FOLDER_NEW=$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/source_files$SOURCE_FOLDER
		SOURCE_FOLDER_PATH=${SOURCE_FOLDER_NEW%/*}
		echo $SOURCE_FOLDER_PATH
 
		if [ ! -d "$SOURCE_FOLDER_PATH" ]
		then
			echo "Directory doesn't exist. Creating now"
			mkdir -p "$SOURCE_FOLDER_PATH"
			echo "$SOURCE_FOLDER_PATH"
			echo "Directory created"
		else
			echo "Directory exists"
		fi 
		cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt | base64 -d > "$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/source_files$SOURCE_FOLDER.catalog"
    fi
    #cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt | base64 -d > "$WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/source_files$SOURCE_FOLDER.catalog"
}
 
function getFolderContents() {
    folder_path="$1"
    echo "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:v2='http://xmlns.oracle.com/oxp/service/v2'>" > $BIP_CONFIG_DIR/FolderContentsV2.xml
    echo "<soapenv:Header/> <soapenv:Body> <v2:getFolderContents>" >> $BIP_CONFIG_DIR/FolderContentsV2.xml
    echo "<v2:folderAbsolutePath>$folder_path</v2:folderAbsolutePath>" >> $BIP_CONFIG_DIR/FolderContentsV2.xml
    echo "<v2:userID>$ERP_USERNAME</v2:userID>" >> $BIP_CONFIG_DIR/FolderContentsV2.xml
    echo "<v2:password>$ERP_PASSWORD</v2:password>" >> $BIP_CONFIG_DIR/FolderContentsV2.xml
    echo "</v2:getFolderContents> </soapenv:Body> </soapenv:Envelope>" >> $BIP_CONFIG_DIR/FolderContentsV2.xml
 
    cat $BIP_CONFIG_DIR/FolderContentsV2.xml
    curl --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:getFolderContents" --data @$BIP_CONFIG_DIR/FolderContentsV2.xml "$BIP_HOST_URL/xmlpserver/services/v2/CatalogService"| xmllint --format - > $BIP_CONFIG_DIR/FolderContentsResponseV2.xml
    cat $BIP_CONFIG_DIR/FolderContentsResponseV2.xml
     if grep -q '<absolutePath>' $BIP_CONFIG_DIR/FolderContentsResponseV2.xml; then
        grep -oP '(?<=<absolutePath>).*?(?=<\/absolutePath>)' $BIP_CONFIG_DIR/FolderContentsResponseV2.xml >> $BIP_CONFIG_DIR/filefolders.txt
 
        while read line; do 
            type=$(echo "example line" | rev | cut -c1-4 | rev)
 
 
            if [[ "${line##*.}" == "xdo" ]]; then
                echo "The file is an .xdo file"
                sed -i '1d' "$BIP_CONFIG_DIR/filefolders.txt"
                echo -e "$line" >> $BIP_CONFIG_DIR/files.txt
            elif [[ "${line##*.}" == "xdm" ]]; then
                echo "The file is an .xdm file"
                sed -i '1d' "$BIP_CONFIG_DIR/filefolders.txt"
                echo -e "$line" >> $BIP_CONFIG_DIR/files.txt
            else
                echo "The file has a different extension"
                sed -i '1d' "$BIP_CONFIG_DIR/filefolders.txt"
                getFolderContents "$line"
            fi
            exec 3<&-
            exec 3<"$BIP_CONFIG_DIR/filefolders.txt"
        done < $BIP_CONFIG_DIR/filefolders.txt
    fi
 
}
 
function get_object(){
FILE_NAME_PATH="$1"
FILE_PATH="$2"
OBJECT_TYPE="$3"
file_name="$1"z
 
       echo  "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:v2='http://xmlns.oracle.com/oxp/service/v2'>" > $BIP_CONFIG_DIR/bipSoapExportV2.xml
       echo "<soapenv:Header/> <soapenv:Body> <v2:getObject>" >> $BIP_CONFIG_DIR/bipSoapExportV2.xml
       echo "<v2:objectAbsolutePath>"$FILE_NAME_PATH"</v2:objectAbsolutePath>" >> $BIP_CONFIG_DIR/bipSoapExportV2.xml
       echo "<v2:userID>$ERP_USERNAME</v2:userID>" >> $BIP_CONFIG_DIR/bipSoapExportV2.xml
       echo "<v2:password>$ERP_PASSWORD</v2:password>" >> $BIP_CONFIG_DIR/bipSoapExportV2.xml
       echo "</v2:getObject> </soapenv:Body> </soapenv:Envelope>" >> $BIP_CONFIG_DIR/bipSoapExportV2.xml
 
       cat $BIP_CONFIG_DIR/bipSoapExportV2.xml
 
       curl --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:getObject" --data @$BIP_CONFIG_DIR/bipSoapExportV2.xml $BIP_HOST_URL/xmlpserver/services/v2/CatalogService | xmllint --format - > $BIP_CONFIG_DIR/exportResponseV2.xml
            #xmllint --xpath "//*[local-name()='archive']/text()" $BIP_CONFIG_DIR/exportResponseV2.xml > $BIP_CONFIG_DIR/exportResponseV2.txt
       cat $BIP_CONFIG_DIR/exportResponseV2.xml
       Var=$(cat $BIP_CONFIG_DIR/exportResponseV2.xml)
       Var1=$(echo $Var | cut -d '<' -f 6)
       #echo "======================================="
       #echo "$Var1"
       #echo "================================="
       Var2=$(echo $Var1 | cut -d '>' -f 2 )
       #echo "================================="   
       #echo "$Var2"    
        echo "$Var2"> $BIP_CONFIG_DIR/exportResponseV2.txt
            SOURCE_FOLDER=$(echo ${FILE_PATH})
            SOURCE_FOLDER_NEW=$BIP_CATALOG_DIR/source_files$SOURCE_FOLDER
            SOURCE_FOLDER_PATH=${SOURCE_FOLDER_NEW%/*}
            echo "source file path is $SOURCE_FOLDER_NEW"
 
            #if [ ! -d "$SOURCE_FOLDER_PATH" ]
            if [ ! -d "$SOURCE_FOLDER_NEW" ]
            then
                echo "Directory doesn't exist. Creating now"
                mkdir -p "$SOURCE_FOLDER_NEW"
                echo "$SOURCE_FOLDER_NEW"
                echo "Source Directory created"
            else
                echo "Directory exists"
            fi    
 
            EXTRACT_FOLDER=$(echo ${FILE_NAME_PATH})
            if [ "$OBJECT_TYPE" == "xdo" ]
            then 
                xml_file="_report.xdo"
            else
                xml_file="_datamodel.xdm"
            fi
            EXTRACT_FOLDER_NEW=$BIP_CATALOG_DIR/extract_files$EXTRACT_FOLDER
            EXTRACT_FOLDER_PATH=${EXTRACT_FOLDER_NEW%/*}
            echo "extract file path is $EXTRACT_FOLDER_NEW"
            #if [ ! -d "$EXTRACT_FOLDER_PATH" ]
            if [ ! -d "$EXTRACT_FOLDER_NEW" ]
            then
                echo "Directory doesn't exist. Creating now"
                mkdir -p "$EXTRACT_FOLDER_NEW"
                echo "$EXTRACT_FOLDER_NEW"
                echo "extract Directory created"
            else
                echo "extract Directory exists"
            fi  
            echo =======================================
            cat $BIP_CONFIG_DIR/exportResponseV2.txt
            #cat $WORKSPACE/BIP_CICD/exportResponseV2.txt | base64 -d > $WORKSPACE/BIP_CICD/source_files$SOURCE_FOLDER.$OBJECT_TYPE
            #cat $FILE_NAME_PATH
            #cat $WORKSPACE/BIP_CICD/exportResponseV2.txt | base64 > $WORKSPACE/BIP_CICD/source_files$FILE_NAME_PATH
            #xxd -r -p $WORKSPACE/BIP_CICD/exportResponseV2.txt > $WORKSPACE/BIP_CICD/source_files$FILE_NAME_PATH
            #xxd -i $WORKSPACE/BIP_CICD/exportResponseV2.txt > $WORKSPACE/BIP_CICD/source_files$FILE_NAME_PATH
            #base64 -d $WORKSPACE/BIP_CICD/exportResponseV2.txt $WORKSPACE/BIP_CICD/source_files$FILE_NAME_PATH
            #cat $BIP_CONFIG_DIR/exportResponseV2.txt > $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/source_files$file_name
            #tar -czvf $WORKSPACE/BIP_CICD/source_files$FILE_NAME_PATH $WORKSPACE/BIP_CICD/exportResponseV2.txt
            cat $BIP_CONFIG_DIR/exportResponseV2.txt | base64 -d > $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/extract_files$FILE_NAME_PATH/$xml_file
			SHARED_OBJECT="/shared$FILE_NAME_PATH"
			export_report_object "$SHARED_OBJECT"
            if grep -q '<getObjectReturn>' $BIP_CONFIG_DIR/exportResponseV2.xml; then
                total_passed=$((total_passed+1))
                total_bi_objects=$((total_bi_objects+1)) 
            else
                total_failed=$((total_failed+1)) 
                total_bi_objects=$((total_bi_objects+1))
            fi
            PATH_WITHOUT_EXT=$(echo $FILE_NAME_PATH | /bin/cut -d. -f1-$(($(echo $FILE_NAME_PATH | /bin/awk -F. '{print NF-1}'))))
 
            log_result "Export object" "$OBJECT_TYPE" "$PATH_WITHOUT_EXT" "$BIP_CONFIG_DIR/exportResponseV2.xml"           
 
}
 
 
 
# end report changes
 
xmllint --format "$WORKSPACE/utils/utils/bip_cicd/config/xmlp-client-config.xml"
 
get_sessionId
 
cd $WORKSPACE/utils/utils/bip_cicd/bin
cat $BIP_CONFIG_LOCATION
total_rec_num=$(jq '. | length' $BIP_CONFIG_LOCATION)
for (( i=0; i < $total_rec_num; i++))
do
    JOB_TYPE=$(jq -r '.['$i'] | .jobType' $BIP_CONFIG_LOCATION)
    OBJECT_TYPE=$(jq -r '.['$i'] | .type' $BIP_CONFIG_LOCATION)
 
    if [ $JOB_TYPE == "Folder" ]
    then
        echo "Inside folder"
        #datamodel and report code starts here for folder jobtype
        OBJECT_PATH=$(jq -r '.['$i'] | .path' $BIP_CONFIG_LOCATION) 
        echo "clearing file" > $BIP_CONFIG_DIR/files.txt
        sed -i '1d' "$BIP_CONFIG_DIR/files.txt"
        getFolderContents "$OBJECT_PATH"
        sort -u $BIP_CONFIG_DIR/files.txt -o $BIP_CONFIG_DIR/duplicate_files.txt
        while read file; do
            # Call the function for each file
            File_WITH_EXT=$(echo "$file" | rev | cut -d/ -f1 | rev)
            typee=$(echo "$File_WITH_EXT" | rev | cut -d. -f1 | rev)
            namee=$(echo $File_WITH_EXT | cut -d. -f1-$(($(echo $File_WITH_EXT | awk -F. '{print NF-1}'))))
            Path=$(echo $file | sed 's/\/[^\/]*$//')
            OBJECT_NAME1=$(echo $namee | sed -e 's/\r//g')
            OBJECT_FULL_PATH="$Path/$namee.$typee"
            echo "object full path is $OBJECT_FULL_PATH and name is $namee"
            get_object "$OBJECT_FULL_PATH" "$Path" "$typee" 
 
        done < $BIP_CONFIG_DIR/duplicate_files.txt
         #datamodel and report code ends here for folder jobtype
 
        ### Start logic for catalog
        CATALOG_PATH=$(jq -r '.['$i'] | .path' $BIP_CONFIG_LOCATION)
        CATALOG_FULL_PATH=$(echo $CATALOG_PATH | tr ' ' '+')
        echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:v12=\"urn://oracle.bi.webservices/v12\">" > $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
        echo "<soapenv:Header/><soapenv:Body><v12:getSubItems>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
        echo "<v12:path>/Shared$CATALOG_PATH</v12:path>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
        echo "<v12:mask>*</v12:mask><v12:resolveLinks>TRUE</v12:resolveLinks>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
        echo "<v12:sessionID>$SESSION_ID</v12:sessionID>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
        echo "</v12:getSubItems></soapenv:Body></soapenv:Envelope>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
 
        curl --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:getSubItems" --data @$WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml $BIP_HOST_URL/analytics-ws/saw.dll?SoapImpl=webCatalogService | xmllint --format - > $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml
        echo ------------------------------------------------------------------------------
        cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml
        nodeCount=$(xmllint --xpath "count(//*[local-name()='path']/text())" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
        echo $nodeCount
        for (( j=1; j <= $nodeCount; j++))
        do
            objectPath=$(xmllint --xpath "//*[local-name()='itemInfo'][$j]/*[local-name()='path']/text()" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
            echo $objectPath
            compositeSignature=$(xmllint --xpath "//*[local-name()='itemInfo'][$j]/*[local-name()='itemProperties']/*[local-name()='name']/text()" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
            echo $compositeSignature
            signature=$(xmllint --xpath "boolean(//*[local-name()='itemInfo'][$j]/*[local-name()='signature']/text())" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
            echo $signature
            hasComSigPresent=''
 
            if [[ $compositeSignature =~ "compositeSignature" ]]
            then
                hasComSigPresent='true'
 
            else
                hasComSigPresent='false'
            fi
 
            if [[ $hasComSigPresent == "false" && $signature == "false" ]]
            then
                echo "$objectPath" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt
            else
                if [[ $objectPath =~ ".xdm" || $objectPath =~ ".xdo" ]]
                then
                    echo "Report object not required"
                else
                    echo "$objectPath" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt
                fi    
            fi
 
        done
 
        isFolderCount=1
 
        touch  $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderNewResults.txt
        touch  $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt
 
        while [ $isFolderCount -lt 2 ]
        do
            while read -r FILE_PATH
            do
                echo "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:v12=\"urn://oracle.bi.webservices/v12\">" > $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
                echo "<soapenv:Header/><soapenv:Body><v12:getSubItems>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
                echo "<v12:path>$FILE_PATH</v12:path>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
                echo "<v12:mask>*</v12:mask><v12:resolveLinks>TRUE</v12:resolveLinks>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
                echo "<v12:sessionID>$SESSION_ID</v12:sessionID>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
                echo "</v12:getSubItems></soapenv:Body></soapenv:Envelope>" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
 
                curl --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:getSubItems" --data @$WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml $BIP_HOST_URL/analytics-ws/saw.dll?SoapImpl=webCatalogService | xmllint --format - > $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml
 
                nodeCount=$(xmllint --xpath "count(//*[local-name()='path']/text())" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
                echo $nodeCount
 
 
                for (( k=1; k <= $nodeCount; k++))
                do
                    objectPath=$(xmllint --xpath "//*[local-name()='itemInfo'][$k]/*[local-name()='path']/text()" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
                    compositeSignature=$(xmllint --xpath "//*[local-name()='itemInfo'][$k]/*[local-name()='itemProperties']/*[local-name()='name']/text()" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
                    signature=$(xmllint --xpath "boolean(//*[local-name()='itemInfo'][$k]/*[local-name()='signature']/text())" $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml)
                    hasComSigPresent=''
 
                    if [[ $compositeSignature =~ "compositeSignature" ]];
                    then
                        hasComSigPresent='true'
 
                    else
                        hasComSigPresent='false'
                    fi
 
                    if [[ $hasComSigPresent == "false" && $signature == "false" ]]
                    then
                        echo "$objectPath" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderNewResults.txt
                    else
                        if [[ $objectPath =~ ".xdm" || $objectPath =~ ".xdo" ]]
                        then
                            echo "Report object not required"
                        else
                            echo "$objectPath" >> $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt
                        fi
                    fi
 
                done
 
            done < "$WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt"
            truncate -s 0 $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt
            cp $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderNewResults.txt $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt
            truncate -s 0 $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderNewResults.txt
 
            if [ -z "$(cat $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt)" ] 
            then
                echo "File is empty"
                isFolderCount=2
            else
                echo "File is not empty"
                isFolderEmpty='N'
            fi
        done
        #cat bipSoapGetFolderResults.txt
        ls $WORKSPACE/utils/utils/bip_cicd/bin
        echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        cat $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt
        while read -r FILE_PATH
        do
            export_report_object "$FILE_PATH" 
 
            if [ -z "$(cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt)" ] 
            then
                total_failed=$((total_failed+1)) 
                total_bi_objects=$((total_bi_objects+1)) 
                echo "Archive Not Found" > $WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt
            else
                total_passed=$((total_passed+1))
                total_bi_objects=$((total_bi_objects+1)) 
                echo "Success" > $WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt
            fi
            log_result "Export Catalog" "catalog" "$OBJECT_PATH/$OBJECT_NAME" "$WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt"           
        done < "$WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt"
 
 
        #rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt
        #rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt
        ### End logic for catalog
        echo =============
        echo '$OBJECT_FULL_PATH'
        #cd $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/extract_files"$OBJECT_FULL_PATH"
        #cd $WORKSPACE/utils/utils/bip_cicd/bin
 
 
    else
        if [ $JOB_TYPE == "File" ]
        then
            if [ -z "$OBJECT_TYPE" ] 
            then
                OBJECT_NAME=$(jq -r '.['$i'] | .name' $BIP_CONFIG_LOCATION)
                OBJECT_PATH=$(jq -r '.['$i'] | .path' $BIP_CONFIG_LOCATION)
                OBJECT_FULL_PATH="/shared$OBJECT_PATH/$OBJECT_NAME"
                export_report_object "$OBJECT_FULL_PATH"
 
                if [ -z "$(cat $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt)" ] 
                then
                    total_failed=$((total_failed+1)) 
                    total_bi_objects=$((total_bi_objects+1)) 
                    echo "Archive Not Found" > $WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt
                else
                    total_passed=$((total_passed+1))
                    total_bi_objects=$((total_bi_objects+1)) 
                    echo "Success" > $WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt
                fi
                log_result "Export Catalog" "catalog" "$OBJECT_PATH/$OBJECT_NAME" "$WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt"
            else
 
                echo "Running for xdo and xdm type of files"
                OBJECT_TYPE=$(jq -r '.['$i'] | .type' $BIP_CONFIG_LOCATION)
                OBJECT_NAME=$(jq -r '.['$i'] | .name' $BIP_CONFIG_LOCATION)
                OBJECT_PATH=$(jq -r '.['$i'] | .path' $BIP_CONFIG_LOCATION)
                OBJECT_NAME1=$(echo $OBJECT_NAME | sed -e 's/\r//g')
                OBJECT_NAME2=$(echo $OBJECT_NAME1 | tr ' ' '+')
                OBJECT_FULL_PATH="$OBJECT_PATH/$OBJECT_NAME1.$OBJECT_TYPE"
                echo "$OBJECT_FULL_PATH"
                get_object "$OBJECT_FULL_PATH" "$OBJECT_PATH" "$OBJECT_TYPE"
                cd $WORKSPACE/utils/utils/bip_cicd/bin
            fi    
        fi
    fi
done
rm -f -- $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/listResponse.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/DataModel.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/DataModelFinal.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/Report.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/ReportFinal.txt
 
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapLogin.xml
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/loginResponse.xml
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.xml
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderResults.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetObjectResults.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetFolderNewResults.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipExportCatalogResponse.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapExport.xml
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/exportResponse.txt
rm -f -- $WORKSPACE/utils/utils/bip_cicd/bin/bipSoapGetItems.xml
rm -f -- $BIP_CONFIG_DIR/bipSoapExportV2.xml
rm -f -- $BIP_CONFIG_DIR/exportResponseV2.txt
rm -f -- $BIP_CONFIG_DIR/exportResponseV2.xml
rm -f -- $BIP_CONFIG_DIR/filefolders.txt
rm -f -- $BIP_CONFIG_DIR/files.txt
rm -f -- $BIP_CONFIG_DIR/duplicate_files.txt
rm -f -- $BIP_CONFIG_DIR/FolderContentsV2.xml
rm -f -- $BIP_CONFIG_DIR/FolderContentsResponseV2.xml
# start report changes
# Converting output to HTML format
 
ciout_to_html $RESULT_OUTPUT $total_bi_objects $total_passed $total_failed
# end report changes
#Notification Integration code starts here
oci secrets secret-bundle get --secret-id ocid1.vaultsecret.oc1.eu-frankfurt-1.amaaaaaahss3fcaaqyhtxkvds5fkaph5nwxdwyskrxm7ognlakuppidub23q > oicUser.json
oci secrets secret-bundle get --secret-id ocid1.vaultsecret.oc1.eu-frankfurt-1.amaaaaaahss3fcaanncbsciuthpkeyon3m4mn5czlaisblswir3iltqcwesa > oicSecret.json
 
integrationUser=$(jq -r ' .data."secret-bundle-content".content' oicUser.json | base64 --decode)
#integrationPassword=$(jq -r ' .data."secret-bundle-content".content' oicSecret.json | base64 --decode)
cd $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/EXPORT_Report_to_GIT
#curl -X POST -u $integrationUser:$integrationPassword  -F 'data=@'$CI_REPORT -F "Build Number"=$BUILD_NUMBER -F "Job Name"=$JOB_NAME -F "BIP Job Type"="Export" -F "Source BIP URL"=$BIP_URL -F "GIT User Email"=$BITBUCKET_EMAIL https://testoics-frf0p9zjd2mi-fr.integration.ocp.oraclecloud.com/ic/api/integration/v1/flows/rest/SEND_VBS_BUILD_JOB_EMAIL/1.0/processVbsBuildJobData
curl -X POST -u $integrationUser:$INTEGRATION_PWD -F 'data=@'$CI_REPORT -F "Build Number"=$BUILD_NUMBER -F "Job Name"="$JOB_NAME" -F "BIP Job Type"="Export" -F "Source BIP URL"=$BIP_URL -F "GIT User Email"=$BITBUCKET_EMAIL https://testoics-frf0p9zjd2mi-fr.integration.ocp.oraclecloud.com/ic/api/integration/v1/flows/rest/SEND_VBS_BUILD_JOB_EMAIL/1.0/processVbsBuildJobData
#Notification Integration code ends here
 
#Test Parameters
mv $WORKSPACE/utils/utils/bip_cicd/xmlp-client-config.xml $WORKSPACE/utils/utils/bip_cicd/config/xmlp-client-config.xml
cd $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip
now=$(date +%d%b%Y-%H.%M.%S)
echo -e "\n" >> $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/export_reports_to_git_log.csv
echo =================================================================================================== >> $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/export_reports_to_git_log.csv
echo BuildNumber: $BUILD_NUMBER " | " BranchName: $BRANCH_NAME " | " Date: $now " | " GitEmail: $GIT_EMAIL   >> $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/export_reports_to_git_log.csv
cat $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/bip_cicd_config.csv >> $WORKSPACE/BOS-EMFI-CI-SaaS-and-PaaS/saas/bip/config/Build-JSON-file-Log/export_reports_to_git_log.csv
