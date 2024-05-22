#function to check if file exists
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

process_country() {
  local country=$1
  local -a gdp_values=()
  local -a cantril_values_gdp=()
  local -a life_expectancy=()
  local -a cantril_values_life=()
  local -a homicide_rate=()
  local -a cantril_values_homicide=()


  while IFS=$'\t' read -r entity code year gdp population_val homicide life_exp cantril; do
    
    if [ "$entity" == "$country" ]; then
        cantril=$(echo "$cantril" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        if [ -n "$cantril" ] && [[ "$cantril" != " " ]]; then
           
            if [ -n "$gdp" ] && [[ "$gdp" != " " ]]; then
                gdp_values+=("$gdp")
                cantril_values_gdp+=("$cantril")
            fi
            if [ -n "$life_exp" ] && [[ "$life_exp" != " " ]]; then
                life_expectancy+=("$life_exp")
                cantril_values_life+=("$cantril")
            fi
            if [ -n "$homicide" ] && [[ "$homicide" != " " ]]; then
                homicide_rate+=("$homicide")
                cantril_values_homicide+=("$cantril")
            fi
        fi
    fi
  done < $2

    
    if [ "${#gdp_values[@]}" -ge 3 ] && [ "${#life_expectancy[@]}" -ge 3 ] && [ "${#homicide_rate[@]}" -ge 3 ]; then
        return 0
    else
        return 1
    fi

}
calculate_mean(){
    sum=$1
    count=$2
    mean=$(echo "scale=10; $sum / $count" | bc)
    echo "$mean"
}

calculate_sum_diff_sqr(){
    values=$1
    mean=$2
    sum_diff_sqr=0 
    for v in $values; do
        diff=$(echo "scale=10; ($v - $mean)^2" | bc)
        sum_diff_sqr=$(echo "scale=10; $sum_diff_sqr + $diff" | bc)
        
    done
    echo "$sum_diff_sqr"
}
calculate_numerator(){
    
    x=$(echo "$1" | tr '\n' ' ')
    y=$(echo "$2" | tr '\n' ' ')
    IFS=' ' read -r -a x_array <<< "$x"
    IFS=' ' read -r -a y_array <<< "$y"

    mean_x=$3
    mean_y=$4
    
    sum_result=0
    # Calculate ∑(X - Mx)(Y - My) for each pair of values and sum the results
    for (( i=0; i<${#x_array[@]}; i++ )); do
    
        x="${x_array[i]}"
        y="${y_array[i]}"
        result=$(echo "scale=10; ($x - $mean_x) * ($y - $mean_y)" | bc)
        sum_result=$(echo "scale=10; $sum_result + $result" | bc)
    done

    echo "$sum_result"

}

calculate_pearson_coefficient()
{
    numerator=$1
    sum_diff_sqr_1=$2
    sum_diff_sqr_2=$3

    sqrt_part=$(echo "scale=10; sqrt($sum_diff_sqr_1 * $sum_diff_sqr_2)" | bc)

    # Calculate the Pearson correlation coefficient
    r=$(echo "scale=10; $numerator / $sqrt_part" | bc)

    # Print the result
    echo "$r"
}

calculate_mean_coff() {
   
    # Declare local variables within the function
    local sum=0
    local count=0

    # Loop through the array elements and accumulate the sum
    for value in "${@}"; do
        sum=$(echo "$sum + $value" | bc)
        ((count++))
    done

    # Calculate the mean
    if (( count > 0 )); then
        mean=$(echo "scale=3; $sum / $count" | bc)
         # Format mean with leading zero before decimal point if mean < 1
        mean_formatted=$(printf "%.3f" "$mean")
        echo "$mean_formatted"
    fi
}

find_highest() {
    local largest_absolute=0
    local largest_absolute_sign=""

    # Iterate over the variables
    for value in "$@"; do
        if [[ $value =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            abs_value=$(echo "${value#-}" | bc)
            if (( $(echo "$abs_value > $largest_absolute" | bc -l) )); then
                largest_absolute=$abs_value
                if [[ $value == -* ]]; then
                    largest_absolute_sign="-"
                else
                    largest_absolute_sign=""
                fi
            fi
        else
            echo "Error: '$value' is not a valid numeric value"
        fi
    done
    largest_absolute_formatted=$(printf "%0.3f" "$largest_absolute")
     echo "${largest_absolute_sign}${largest_absolute_formatted}"
}

compute_cor(){
    countries=$1
    filtered_data=$2

    gdp_coff_values=()
    population_coff_values=()
    homicide_coff_values=()
    life_expectancy_coff_values=()

    for country in $countries; do
       
        Country_data=$(awk -v country="$country" '$1 == country {print}' <<< "$filtered_data")
        
        #Get all the predictor values
        cantril_score=$(awk -F'\t' '$8 != "" {print $8}' <<< "$Country_data")
        gdp=$(awk -F'\t' '$8 != "" {print $4}' <<< "$Country_data")
        population=$(awk -F'\t' '$8 != "" {print $5}' <<< "$Country_data")
        homicide=$(awk -F'\t' '$8 != "" {print $6}' <<< "$Country_data")
        life_expectancy=$(awk -F'\t' '$8 != "" {print $7}' <<< "$Country_data")

        #Get the count
        n=$(awk -F'\t' '$8 != "" {count++} END {print count}' <<< "$Country_data")

       
        # Get sum of all the predictors
        sum_cantril_score=$(awk -F'\t' '$8 != "" {sum += $8} END {print sum}' <<< "$Country_data")
        sum_gdp=$(awk -F'\t' '$8 != "" {sum += $4} END {print sum}' <<< "$Country_data")
        sum_population=$(awk -F'\t' '$8 != "" {sum += $5} END {print sum}' <<< "$Country_data")
        sum_homicide=$(awk -F'\t' '$8 != "" {sum += $6} END {print sum}' <<< "$Country_data")
        sum_life_expectancy=$(awk -F'\t' '$8 != "" {sum += $7} END {print sum}' <<< "$Country_data")
        
        #Common
        mean_score=$(calculate_mean "$sum_cantril_score" "$n")
        sum_diff_sqr_score=$(calculate_sum_diff_sqr "$cantril_score" "$mean_score")

        # Calculate for GDP
        mean_gdp=$(calculate_mean "$sum_gdp" "$n")
        sum_diff_sqr_gdp=$(calculate_sum_diff_sqr "$gdp" "$mean_gdp")
        numerator=$(calculate_numerator "$gdp" "$cantril_score" "$mean_gdp" "$mean_score")
       
        coffetaint_gdp_score=$(calculate_pearson_coefficient "$numerator"  "$sum_diff_sqr_gdp" "$sum_diff_sqr_score")
        gdp_coff_values+=("$coffetaint_gdp_score")

        # Calculate for population
        mean_population=$(calculate_mean "$sum_population" "$n")
        sum_diff_sqr_population=$(calculate_sum_diff_sqr "$population" "$mean_population")
        numerator=$(calculate_numerator "$population" "$cantril_score" "$mean_population" "$mean_score")
        coffetaint_population_score=$(calculate_pearson_coefficient "$numerator"  "$sum_diff_sqr_population" "$sum_diff_sqr_score")
        population_coff_values+=($coffetaint_population_score)

        # Calculate for homicide
        mean_homicide=$(calculate_mean "$sum_homicide" "$n")
        sum_diff_sqr_homicide=$(calculate_sum_diff_sqr "$homicide" "$mean_homicide")
        numerator=$(calculate_numerator "$homicide" "$cantril_score" "$mean_homicide" "$mean_score")
        coffetaint_homicide_score=$(calculate_pearson_coefficient "$numerator"  "$sum_diff_sqr_homicide" "$sum_diff_sqr_score")
        homicide_coff_values+=($coffetaint_homicide_score)

         # Calculate for life_expectancy
        mean_life_expectancy=$(calculate_mean "$sum_life_expectancy" "$n")
        sum_diff_sqr_life_expectancy=$(calculate_sum_diff_sqr "$life_expectancy" "$mean_life_expectancy")
        numerator=$(calculate_numerator "$life_expectancy" "$cantril_score" "$mean_life_expectancy" "$mean_score")
        coffetaint_life_score=$(calculate_pearson_coefficient "$numerator"  "$sum_diff_sqr_life_expectancy" "$sum_diff_sqr_score")
        life_expectancy_coff_values+=($coffetaint_life_score)
        

        
    done
    
    #calculate mean 
    
    mean_gdp=$(calculate_mean_coff "${gdp_coff_values[@]}")
    mean_population=$(calculate_mean_coff "${population_coff_values[@]}")
    mean_homicide=$(calculate_mean_coff "${homicide_coff_values[@]}")
    mean_life=$(calculate_mean_coff "${life_expectancy_coff_values[@]}")

    echo "Mean correlation of Homicide Rate with Cantril ladder is $mean_homicide"
    echo "Mean correlation of GDP with Cantril ladder is $mean_gdp"
    echo "Mean correlation of Population with Cantril ladder is $mean_population"
    echo "Mean correlation of Life Expectancy with Cantril ladder is $mean_life"

    predictive=$(find_highest "$mean_homicide" "$mean_homicide" "$mean_population" "$mean_life")
    if [ "$predictive" == "$mean_homicide" ]; then
        echo "Most predictive mean correlation with the Cantril ladder is Homicide (r = "$predictive")"
    elif [ "$predictive" == "$mean_gdp" ]; then
        echo "Most predictive mean correlation with the Cantril ladder is GDP (r = "$predictive")"
    elif [ "$predictive" == "$mean_population" ]; then
        echo "Most predictive mean correlation with the Cantril ladder is Population (r = "$predictive")"
    else
        echo "Most predictive mean correlation with the Cantril ladder is Life Expectancy (r = "$predictive")"
    fi



}


if [ $# -ne 1 ]; then
    echo "Error : The arguments are missing"
    exit 1

else
    filename=$1

    if check_file_exists "$filename"; then
        
        unique_countries=$(awk -F'\t' 'NR > 1 {print $1}' "$filename" | sort | uniq)
        
        #Iterate over each country to check if it has atleast 3 data points
        declare -a successful_countries=()

        while IFS=$'\t' read -r country; do
           
            #Add your processing logic here
            if process_country "$country" "$filename"; then
                successful_countries+=("$country")
            fi
        done <<< "$unique_countries"
        
        
        if [ ${#successful_countries[@]} -ne 0 ]; then
            
            # Now we will calculate pearson coffetaint

            pattern=$(IFS="|"; echo "${successful_countries[*]}")
            filtered_data=$(awk -v pattern="$pattern" '$0 ~ pattern' $filename)

            #create file with filtered data
            echo "$filtered_data" > temp_data_predictor_TEST.tsv
            
            # Extract unique countries from file created
            countries=$(awk 'NR>1 {print $1}' temp_data_predictor_TEST.tsv | sort | uniq)
            
            predictors=("GDP" "Population" "Unemployment" "Life_Expectancy" "Score" "Homicide")


            compute_cor "$countries" "$filtered_data"


        else
            echo "Error : There is no data with atleast 3 data points" 
        fi

    else
        echo "The named input file $filename does not exist or has zero length"
    fi

fi