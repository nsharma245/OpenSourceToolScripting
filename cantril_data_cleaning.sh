
is_tsv() {
   
    first_line=$(head -n 1 "$1")
    #echo "$first_line"

    # Use awk to split the line into fields using tabs as delimiter and count the number of fields
    num_fields=$(echo "$first_line" | awk -F '\t' '{print NF}')
    #echo "$num_fields"

    if [ "$1" = "gdp.tsv" ]; then
        if [ "$num_fields" -eq "7" ]; then
            return 0 # true, header has expected number of fields
        else
            return 1 # false, header does not have expected number of fields
        fi
    elif [ "$1" = "homicide-rate-unodc.tsv" ];then
        if [ "$num_fields" -eq "4" ]; then
            return 0 # true, header has expected number of fields
        else
            return 1 # false, header does not have expected number of fields
        fi
    elif [ "$1" = "life-satisfaction-vs-life-expectancy.tsv" ];then
        if [ "$num_fields" -eq "7" ]; then
            return 0 # true, header has expected number of fields
        else
            return 1 # false, header does not have expected number of fields
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

check_file_data() {
    header=$(head -n 1 "$1")
    #echo "Header:"
    echo "$header"
    #> output.tsv

    if [ "$1" = "gdp.tsv" ]; then

        #echo "$header" > output.tsv
        > output.tsv
        # Read the TSV file line by line
        while IFS=$'\t' read -r -a fields; do
            
            # Count the number of fields in the current line
            num_fields=${#fields[@]}
            echo "Number of fields in the line: $num_fields"
           if [ "$num_fields" = "7" ]; then
                second_column="${fields[1]}"
            else
                echo "${fields[@]}"
            fi
            echo "${fields[@]}" >> output.tsv
            
            
        done < "$1"
        echo "$(pwd)/output.tsv"
    else
        echo "nnnnnnnnnnnnnnnn"   
    fi
    
}




# Check if the number of arguments is not equal to 3
if [ "$#" -ne 3 ]; then
    echo "Error : The arguments are missing"
    exit 1

else
    # file_name_1="$1"
    # file_name_2="$2"
    # file_name_3="$3"

  
    # Check for each file
    for file in "$@"; do
        #echo "$file"
        if check_file_exists "$file"; then
            
            if is_tsv "$file"; then
                echo " $file is correct file"
                output_file=$(check_file_data "$file")
                file_content=$(cat output.tsv)
                echo "$file_content"

            else
                echo "Error: $file is not in tab-separated format or the number of argumnets are not same as required"
                
            fi
        else
            echo "Error : $file does not exists"
        fi

    done

fi

