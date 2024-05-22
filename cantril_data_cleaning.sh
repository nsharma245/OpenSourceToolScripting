
#Function ti check if the file is tsv
is_tsv() {
   
    first_line=$(head -n 1 "$1")
    
    # Use awk to split the line into fields using tabs as delimiter and count the number of fields
    num_fields=$(echo "$first_line" | awk -F '\t' '{print NF}')
    
    if [ "$1" = "gdp.tsv" ]; then
        if [ "$num_fields" -eq "7" ]; then
            return 0
        else
            return 1
        fi
    elif [ "$1" = "homicide-rate-unodc.tsv" ];then
        if [ "$num_fields" -eq "4" ]; then
            return 0
        else
            return 1 # false, header does not have expected number of fields
        fi
    elif [ "$1" = "life-satisfaction-vs-life-expectancy.tsv" ];then
        if [ "$num_fields" -eq "7" ]; then
            return 0
        else
            return 1 
        fi
    else
        return 0
    fi  
}

# Function to check if file exsist or have 0 length
check_file_exists(){
    filename="$1"
    
    if [ -f "$filename" ]; then

        # Check if the trimmed content is empty
        trimmed_content=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$filename")
        if [ -z "$trimmed_content" ]; then
            return 1
        else
            return 0
        fi
    else
        return 1
    fi    
}

#Function to check the file data
check_file_data() {
    echo "________$1 __________"
    header=$(head -n 1 "$1")
    echo "$header"
    # report the invalid lines to stdout
    awk -F'\t' -v file_name="$1" '
    NR == 1 { header_fields = NF }
    NR > 1 { 
        if (NF != header_fields) 
             print "Invalid Line " NR " "NF" in file " file_name ": Field count mismatch."
    }' "$1"
    
    input_file="$1"
    output_file="TEST_${input_file}"
    
    # Check if the last field of the header contains "Continent" and remove it
    last_field=$(awk -F '\t' 'NR==1 {print $NF}' "$input_file")
    if [[ $last_field == *"Continent"* ]]; then
        remove_continent="true"
        # Modify the header to remove the "Continent" field
        header=$(head -n 1 "$input_file" | rev | cut -f 2- | rev)

    else
        remove_continent="false"
        header=$(head -n 1 "$input_file")
    
    fi

    # Print the modified header
    echo "$header" > "$output_file"

    # Process the input file and check for year ranage and empty country codes
    awk -F '\t' -v remove_continent="$remove_continent" '
        NR > 1 {
            if (NF == num_fields && $2 != "" && $3 >= 2011 && $3 <= 2021) {
                if (remove_continent == "true") {
                    # Print all fields except the last field (Continent)
                    printf "%s", $1;
                    for (i = 2; i < NF; i++) {
                        printf "\t%s", $i;  # Print tab-separated fields
                    }
                    printf "\n";  # End of line
                } else {
                    print $0;  # Print the whole row
                }
            }
        }
    ' num_fields=$(awk -F '\t' 'NR==1 {print NF}' "$input_file") "$input_file" >> "$output_file"

}


# Check if the number of arguments is not equal to 3
if [ "$#" -ne 3 ]; then
    echo "Error : The arguments are missing"
    exit 1

else
  
    # Check for each file
    for file in "$@"; do
        #echo "$file"
        if check_file_exists "$file"; then
            
            if is_tsv "$file"; then
                
                check_file_data "$file"
                
                # Define input files
                GDP_FILE="TEST_gdp.tsv"
                LIFE_FILE="TEST_life.tsv"
                HOME_FILE="TEST_homicide.tsv"
                OUTPUT_FILE="clean_data_test.tsv"

            
               
                # Extract headers from the first file
                HEADERS=$(head -n 1 "$LIFE_FILE")
                
                # Append columns from the second file to the headers, excluding the first three columns
                SECOND_FILE_HEADERS=$(head -n 1 "$GDP_FILE" | cut -f4-)
                
                # Combine headers with columns from the second file
                HEADERS="$HEADERS"$'\t'"$SECOND_FILE_HEADERS"

                
                # Write headers to the output file
                echo -e "$HEADERS" > "$OUTPUT_FILE"
                # # Use awk to join first 2 files 
                awk -F'\t' 'NR==FNR {a[$1$2$3]=$0; next} ($1$2$3 in a) {print a[$1$2$3] "\t" substr($0, index($0, $4))}' OFS='\t' "$LIFE_FILE" "$GDP_FILE" | tail -n +2 >> "$OUTPUT_FILE"

                #Append columns from the third file to the headers, excluding the first three columns
                THIRD_FILE_HEADERS=$(head -n 1 "$HOME_FILE" | cut -f4-)
                
                HEADERS="$HEADERS"$'\t'"$THIRD_FILE_HEADERS"
                # Use awk to join files based on the first three columns
                awk -F'\t' 'NR==FNR {a[$1$2$3]=$0; next} ($1$2$3 in a) {print a[$1$2$3] "\t" substr($0, index($0, $4))}' OFS='\t' "$OUTPUT_FILE" "$HOME_FILE" | tail -n +2 >> "final.tsv"


            else
                echo "Error: $file is not in tab-separated format or the number of argumnets are not same as required"
                
            fi
        else
            echo "Error : $file does not exists"
        fi

    done

    # Check if the file exists and has at least two lines (header + data)
    if [[ ! -f "final.tsv" ]] || [[ $(wc -l < "final.tsv") -lt 2 ]]; then
        echo -e "\n\nCleaned Data :\n"
        echo "Error: No data is found !"
        exit 1
    else
        echo -e "\n\nCleaned Data :\n"
        awk 'BEGIN { FS = "\t"; OFS = "\t" }
                { 
                    # Trim leading and trailing whitespace from each field
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $8)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $6)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $10)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4)

                    # Print the fields
                    print $1, $2, $3, $8, $6, $10, $4, $7
                }' final.tsv

    fi

    

        

fi

