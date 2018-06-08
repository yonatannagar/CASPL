//
// Created by eyalshag on 3/26/18.
//
#include <stdio.h>
#include <stdbool.h>
#include <malloc.h>
#include <stdlib.h>
#include <memory.h>

typedef struct bignum{
    long number_of_digits;
    char *digits;
} bignum;

extern bignum* s_add(bignum* first, bignum* second);
extern bignum* s_sub(bignum* first, bignum* second);

bignum *div_by_two(bignum *bignum);

bool negFlag =false;
bignum* stack [1024];
int sp=0;

//Stack operations
void s_push(bignum *e){
    if (sp==1024){
        printf("stack is full");
    }
    stack[sp]=e;
    sp++;
}
bignum* s_pop(){
    if (sp==0){
        printf("no elements in stack\n");
        return stack[sp];
    }
    sp--;
    return (stack [sp]);
}
bignum* peek (){
    if (sp==0){
        printf("no elements in stack\n");
        return NULL;
    }
    return stack[sp-1];
}
void print(){
    bignum* res = peek();
    if(res == NULL)
        return;
    for (long i=0; i<res->number_of_digits; i++){
        if (res->digits[i]=='_'){
            putchar('-');
        }
        else putchar(res->digits[i]);
    }
    putchar('\n');
}

//BN modifications methods
void bn_free(bignum *bn){
    free(bn->digits);
    free(bn);
}
bignum* extend_bignum(bignum* bn, char c){

    bn->digits=realloc(bn->digits, (size_t) (bn->number_of_digits + 1));
    for(long i=(bn->number_of_digits); i>0; i--){
        bn->digits[i]=bn->digits[i-1];
    }
    bn->digits[0]=c;
    bn->number_of_digits++;

    return bn;
}

bignum* generateBNspecific (char c){
    bignum* factor = malloc(16);
    factor->number_of_digits=1;
    char* str = malloc((size_t) 1);
    str[0]=c;
    factor->digits=str;
    return factor;
}

bignum* mini_bignum(bignum* bn){
    if(bn->digits[0] != '0')    //easy case: no fix needed, return same BN
        return bn;

    bignum* result;
    long new_digits_num = 0;

    bool flag=false;//until seen a number
    for ( long i=0; i<bn->number_of_digits ; i++ ){
        if(!flag && bn->digits[i] != '0')
            flag = true;
        if(flag)
            new_digits_num++;
    }
    if(new_digits_num == 0){
        result = generateBNspecific('0');
        bn_free(bn);
    }else {
        char *str = malloc((size_t) new_digits_num);
        long j=0;
        for (long i = (bn->number_of_digits - new_digits_num); i < bn->number_of_digits; i++) {
            str[j] = bn->digits[i];
            j++;
        }
        free(bn->digits);
        bn->digits=str;
        bn->number_of_digits=new_digits_num;

        result=bn;
    }

    return result;

}
void popAndFree(){
    int lsp = sp+1;
    for (int i=0; i<lsp; i++){
        if(i==lsp-1)
            break;

        else
            bn_free(s_pop());

    }
}
//removes - from the number
void fixNegNumber(bignum* negNumber){
    char *c = malloc(negNumber->number_of_digits-1);
    char *old = negNumber->digits;

    for (int i=1; i<negNumber->number_of_digits; i++)
        c[i-1]=old[i];

    negNumber->digits = c;
    free(old);
    negNumber->number_of_digits--;
}
void fixPosNumber (bignum* posNumber){
    extend_bignum(posNumber, '_');
}
bool is_second_bigger(bignum *first, bignum *second) {
    if(first->number_of_digits > second->number_of_digits)
        return false;

    else if(second->number_of_digits > first->number_of_digits)
        return true;

    else{
        for(long i=0 ; i<first->number_of_digits ; i++){
            if(first->digits[i] > second->digits[i])
                return false;
            else if (second->digits[i] > first->digits[i])
                return true;
        }
    }
    //numbers are equal, arbitrary returning bn1
    return false;
}
int signCheckAndFix (bignum* first, bignum* second){
    char firstSignIndex = first->digits[0];
    char secondSignIndex = second->digits[0];
    if (firstSignIndex!='_' && secondSignIndex!='_'){ //Both positive
        return 0;
    }
    else if (firstSignIndex!='_' && secondSignIndex=='_'){ //first positive, second negative
        fixNegNumber(second);
        return 1;
    }
    else if (firstSignIndex=='_' && secondSignIndex!='_') { //first negative, second positive
        fixNegNumber(first);
        return 2;
    }
    else{// if (firstSignIndex=='_' && secondSignIndex=='_') { //Both negative
        fixNegNumber(first);
        fixNegNumber(second);
        return 3;
    }
}

bool isNum (char c){
    if (c=='_'){
        negFlag=true;
    }
    return (c>='0' && c<='9');
}
void bignumGenerator (char* digits, long number_of_digits) {
    bignum *num = malloc(16);
    num->digits = digits;
    num->number_of_digits = number_of_digits;
    num = mini_bignum (num);
    if (negFlag && num->digits[0] != '0'){
        fixPosNumber(num);
    }
    s_push(num);
}

//duplicates bignum
bignum* bn_copy(bignum* bn){
    bignum* copy = malloc(16);
    copy->number_of_digits=bn->number_of_digits;
    copy->digits = malloc((size_t) bn->number_of_digits);
    for (long i=0; i<bn->number_of_digits; i++){
        copy->digits[i] = bn->digits[i];
    }
    return copy;
}

bignum * add (bignum *first, bignum *second, int caseIndex){
    switch (caseIndex){
        case 0: //Both positive
            if (is_second_bigger(first, second)){
                first=s_add(second, first);
            }
            else first=s_add(first, second);
            break;
        case 1: //first positive, second negative
            if (is_second_bigger(first, second)){
                first=s_sub(second, first);
                negFlag = true;
            }
            else first=s_sub(first, second);
            break;
        case 2: //first negative, second positive
            if (is_second_bigger(first, second)){
                first=s_sub(second, first);
            }
            else{
                first=s_sub(first, second);
                negFlag = true;
            }
            break;
        case 3: //Both negative
            if (is_second_bigger(first, second)){
                first=s_add(second, first);
            }
            else first=s_add(first, second);
            negFlag=true;
            break;
        default: break;
    }
    return first;
}

//returns bn1 * 2
bignum* mul_by_two(bignum* bn1){
    bignum* bn2 = bn_copy(bn1);
    return s_add(bn1, bn2);
}

bool is_even(char c){
    if(c == '0' || c == '2' || c == '4' || c == '6' || c == '8')
        return true;
    return false;
}
bignum* div_by_two(bignum* bn) {
    bn = extend_bignum(bn, '0');//bn = ["0"]+bn->digits update
    long digits_num = bn->number_of_digits;
    bn->number_of_digits=0;
    long j = 0;
    for(long i = 0; i < (digits_num -1) ; ++i){ //window of 2 chars, [i],[j]
        j = i+1;
        if( is_even(bn->digits[i]) ){//first digit is even
            if(bn->digits[j] == '0' || bn->digits[j] == '1'){
                bn->number_of_digits++;
                bn->digits[i]='0';
            }
            else if(bn->digits[j] == '2' || bn->digits[j] == '3'){
                bn->number_of_digits++;
                bn->digits[i]='1';
            }
            else if(bn->digits[j] == '4' || bn->digits[j] == '5'){
                bn->number_of_digits++;
                bn->digits[i]='2';
            }
            else if(bn->digits[j] == '6' || bn->digits[j] == '7'){
                bn->number_of_digits++;
                bn->digits[i]='3';
            }
            else{
                bn->number_of_digits++;
                bn->digits[i]='4';
            } //if(bn->digits[j] == '8' || bn->digits[j] == '9'){}
        }else{ //first digit is odd
            if(bn->digits[j] == '0' || bn->digits[j] == '1'){
                bn->number_of_digits++;
                bn->digits[i]='5';
            }
            else if(bn->digits[j] == '2' || bn->digits[j] == '3'){
                bn->number_of_digits++;
                bn->digits[i]='6';
            }
            else if(bn->digits[j] == '4' || bn->digits[j] == '5'){
                bn->number_of_digits++;
                bn->digits[i]='7';
            }
            else if(bn->digits[j] == '6' || bn->digits[j] == '7'){
                bn->number_of_digits++;
                bn->digits[i]='8';
            }
            else{
                bn->number_of_digits++;
                bn->digits[i]='9';
            } //if(bn->digits[j] == '8' || bn->digits[j] == '9'){}
        }
    }
    bn->digits[j]=0;
    bn = mini_bignum(bn);
    return bn;
}
//KEEPS allows add: gets a+=b,kills b, returns c completely different bignum(@address)
bignum* s2_add(bignum* first, bignum* second){
    bignum* result = bn_copy(first);
    result = s_add(result, second);
    return result;
}
//KEEPS first and second intact, completely new result
bignum* s3_sub(bignum *first, bignum *second){
    bignum* toClear = bn_copy(second);
    first = s_sub(first, toClear);
    return first;
}
bignum* s3_add(bignum* first, bignum* second){
    bignum* toClear = bn_copy(second);
    first = s_add(first, toClear);
    return first;
}
bignum* multiply(bignum *first, bignum *second, bignum *result) {
    if (second->number_of_digits==1 && second->digits[0]=='1'){ //if second==1
        if(is_second_bigger(first, result)) //first < result ??
            result=s2_add(result,first);
        else
            result=s2_add(first,result);
        return result;
    }
    if (!is_even(second->digits[(second->number_of_digits)-1])){ //if second is odd number
        if(is_second_bigger(first, result)) //first < result ??
            result=s2_add(result,first);
        else
            result=s2_add(first,result);
    }
    first = mul_by_two(first);
    second = div_by_two (second);

    result=multiply(first, second, result);
    return result;
}
//DEEP COPY, FREE SECOND
bignum* special_copy (bignum* first, bignum* second){
    if (second->number_of_digits>first->number_of_digits){
        char* tmpD;
        long tmpN;
        tmpD=first->digits;
        first->digits = second->digits;
        second->digits=tmpD;
        tmpN=first->number_of_digits;
        first->number_of_digits=second->number_of_digits;
        second->number_of_digits=tmpN;
    }
    else {
        first->number_of_digits = second->number_of_digits;
        for (long i = 0; i < first->number_of_digits; i++) {
            first->digits[i] = second->digits[i];
        }
    }
    bn_free(second);
    return first;
}

void div_helper(bignum *first, bignum *second, bignum *result, bignum *factor) {
    if (is_second_bigger(first, second)){ //if first<second
        second=div_by_two (second);
        factor=div_by_two(factor);
        return;
    }
    factor=mul_by_two(factor);
    second=mul_by_two(second);
    div_helper(first,second,result,factor);

    bignum* c_sec = bn_copy(second);
    bignum* c_first = bn_copy(first); //NEW
    bignum* c_factor = bn_copy(factor);
    bignum* c_result = bn_copy(result); //NEW
    if (!is_second_bigger(first, second)){ //if first>=second
        c_first = s3_sub(c_first, c_sec); //first - second(copy) and frees second(copy), original sec remains intact
        if(is_second_bigger(result, factor)) { //fact > result
            c_result=s2_add(c_factor, c_result);
        }
        else{ //result >= fact
            c_result= s3_add(c_result,c_factor);

        }
    }

    c_sec = div_by_two(c_sec);
    c_factor = div_by_two(c_factor);

    result=special_copy(result,c_result);
    first=special_copy(first,c_first);
    factor=special_copy(factor,c_factor);
    second=special_copy(second,c_sec);


    return;
}

void divide(bignum *first, bignum *second, bignum *result, bignum *factor) {
    if(!is_second_bigger(first, second)) { //if f >= s
        div_helper(first, second, result, factor);
        if (!is_second_bigger(first, second)) { //if first>=second
            result = s3_add(result, factor);
        }
    }
}

bignum* sub (bignum *first, bignum *second, int caseIndex) {
    switch (caseIndex){
        case 0: //Both positive
            if (is_second_bigger(first, second)){
                first=s_sub(second, first);
                negFlag=true;
            }
            else first=s_sub(first, second);
            break;
        case 1: //first positive, second negative
            if (is_second_bigger(first, second)){
                first=s_add(second, first);
            }
            else first=s_add(first, second);
            break;
        case 2: //first negative, second positive
            if (is_second_bigger(first, second)){
                first=s_add(second, first);
            }
            else first=s_add(first, second);
            negFlag =true;
            break;
        case 3: //Both negative
            if (is_second_bigger(first, second)){
                first=s_sub(second, first);
            }
            else {
                first=s_sub(first, second);
                negFlag = true;
            }
            break;
        default: break;
    }
    return first;
}
bignum * mult (bignum *first, bignum *second, int caseIndex){
    bignum* result = generateBNspecific('0');
    if((first->number_of_digits==1 && first->digits[0] == '0') || (second->number_of_digits==1 && second->digits[0] == '0')){
        bn_free(first);
        bn_free(second);
        return result;
    }
    if (caseIndex==1 || caseIndex==2){
        negFlag=true;
    }
    if(is_second_bigger(first, second))
        result = multiply(second, first, result);
    else
        result = multiply(first, second, result);

    bn_free(first);
    bn_free(second);

    return result;
}

bignum * divi (bignum *first, bignum *second, int caseIndex){
    if (second->number_of_digits==1 && second->digits[0]=='0'){ // if second==0
        bn_free(first);
        bn_free(second); //Delete first and second
        return NULL;
    }
    if (caseIndex==1 || caseIndex==2) {
        negFlag = true;
    }
    bignum* result=generateBNspecific('0');
    bignum* factor=generateBNspecific('1');
    divide(first, second, result, factor);
    bn_free(factor);
    bn_free(first);
    bn_free(second);


    return result;
}

void arithmeticControl (int functionIndex){
    bignum* second = s_pop();
    bignum* first = s_pop();
    bignum* result=NULL;
    int caseIndex=signCheckAndFix(first,second); //fixed cases: ++ +- -+ --, makes so operator works on positive numbers and fixes later
    switch (functionIndex){//funcIndex comes from main operators: + 0 :: - 1 :: * 2 :: / 3
        case 0: //Addition
            result=add (first, second, caseIndex);
            break;
        case 1: //Subtraction
            result=sub (first, second, caseIndex);
            break;
        case 2: //Multiplication
            result=mult (first, second, caseIndex);
            break;
        case 3: //Division
            result=divi (first, second, caseIndex);
            break;
        default: break;
    }
    if (result==NULL)
        return;
    if (negFlag && result->digits[0] != '0'){
        fixPosNumber (result);
    }
    s_push(result);
    negFlag=false;
}


int main () {
    char c;
    bool numFlag = false;
    char *digits_buffer = NULL;
    long digits_number = 0;
    size_t buffer_size = 0;
    void resetAll(){
        digits_number = 0;
        digits_buffer=NULL;
        buffer_size=0;
        numFlag = false;
        negFlag=false;
    }
    while (1) {
        c = (char) fgetc(stdin);
        switch (c) {
            case ('+') :
                if (numFlag){
                    bignumGenerator(digits_buffer, digits_number);
                    resetAll();
                }
                arithmeticControl(0);
                break;
            case '-':
                if (numFlag) {
                    bignumGenerator(digits_buffer, digits_number);
                    resetAll();
                }
                arithmeticControl(1);
                break;
            case '*':
                if (numFlag) {
                    bignumGenerator(digits_buffer, digits_number);
                    resetAll();
                }
                arithmeticControl(2);
                break;
            case '/':
                if (numFlag) {
                    bignumGenerator(digits_buffer, digits_number);
                    resetAll();
                }
                arithmeticControl(3);
                break;
            case 'c':
                if (numFlag){
                    bignumGenerator(digits_buffer, digits_number);
                    resetAll();
                }
                popAndFree();
                break;
            case 'p':
                if (numFlag){
                    bignumGenerator(digits_buffer, digits_number);
                    resetAll();
                }
                print();
                break;
            case 'q':
                fclose(stdin);
                popAndFree();
                return 0;
            default:
                if (isNum(c)) {
                    if (!numFlag) {
                        buffer_size = sizeof(char);
                        digits_buffer = (char *) malloc(buffer_size);
                        digits_buffer[0] = c;
                        digits_number = 1;
                        numFlag = true;
                    }
                    else {
                        buffer_size = buffer_size + sizeof(char);
                        digits_buffer = realloc(digits_buffer, buffer_size);
                        digits_buffer[digits_number] = c;
                        digits_number++;
                    }
                }
                else {
                    if (numFlag) {
                        bignumGenerator(digits_buffer, digits_number);
                        resetAll ();
                    }
                }
        }
    }
}