#
# $Id: makl_code.sh,v 1.1 2008/10/09 09:48:47 stewy Exp $
#

##\brief Compile a C file.
##
##  Compile a C file \e $1 with the supplied flags \e $2.
## 
##   \param $1 Pathname of the C file to be compiled 
##   \param $2 flags to be passed to the compiler
##   \return 0 on success, 1 on failure
##
makl_compile ()
{
    if [ -z "$1" ]; then
        makl_err 1 "makl_compile called with no arguments"
    fi

    c_file=$1
    shift
    flags=$*
    cwd=`pwd`

    makl_dbg "makl_compile ${c_file}"
   
    cp ${c_file} ${makl_run_dir} 2>/dev/null
    cd ${makl_run_dir}

    makl_dbg "$ " ${CC} ${CFLAGS} -o out `basename ${c_file}` ${flags} ${LDFLAGS}
    ${CC} ${CFLAGS} -o out `basename ${c_file}` ${flags} ${LDFLAGS} 2>/dev/null

    if [ $? -ne 0 ]; then
        makl_info "compilation failed"
        cd ${cwd} 
        return 1
    fi 

    cd ${cwd}
    return 0
}

##\brief Write to a C file. 
##
##  Write to a C file. Data is read from standard input.
## 
##   \param $1 name of file to be written
##   \param $2 whether the code is a snippet (1) or entire C file (0)
##   \param $3 file containing code
##
makl_write_c ()
{
    # create a clean file
    [ -r "$1" ] && rm -f $1

    if [ $2 -eq 1 ]; then
        ${ECHO} "int main() {" >> $1
    fi
    
    cat $3 >> $1
    
    if [ $2 -eq 1 ]; then
        {
        ${ECHO} "return 0;"
        ${ECHO} "}"
        } >> $1
    fi
    
    return 0
}

##\brief Compile C code.
##
##  Compile C code.
##
##   \param $1 whether the code is a snippet (1) or entire C file (0)
##   \param $2 file containing code 
##   \param $3 flags to be passed to the compiler
##
makl_compile_code ()
{
    file=${makl_run_dir}/makl_code.c

    makl_write_c ${file} $1 $2

    makl_compile ${file} $3
    [ $? -eq 0 ] || return 1

    return 0
}

##\brief Execute C code.
##
##  Execute C code.
##
##   \param $1 whether the code is a snippet (1) or entire C file (0)
##   \param $2 file containing code
##   \param $3 flags to be passed to the compiler
## 
makl_exec_code ()
{
    file=${makl_run_dir}/makl_code.c
    cwd=`pwd`
    
    makl_write_c ${file} $1 $2
    makl_compile ${file} $3 
    [ $? -eq 0 ] || return 1

    # skip execution on cross-compilation
    [ -z `makl_get "__cross_compile__"` ] || return 0

    cd ${makl_run_dir} && eval ./out > /dev/null 2> /dev/null
    if [ $? -ne 0 ]; then 
        cd ${cwd}
        return 2
    fi

    cd ${cwd}
    return 0
}

##\brief Check existence of a function.
##
##  Define HAVE_$1 if function \e $1 is found.
##  \e $1 determines whether the feature is optional or required.
##
##   \param $1 0:optional/1:required
##   \param $2 function name
##   \param $3 flags to be passed to the compiler
##
makl_checkfunc ()
{
    tmpfile=${makl_run_dir}/snippet.c

    [ -z `makl_get "__noconfig__"` ] || return

    makl_info "checking for function $2"

    ${ECHO} "$2();" > ${tmpfile}
   
    makl_compile_code 1 ${tmpfile} "$3"

    if [ $? -eq 0 ]; then
        makl_set_var "HAVE_"`makl_upper $2`
        return 0
    else
        [ $1 -eq 0 ] || makl_err 1 "failed check on required function $2!"
        makl_warn "failed check on optional function $2"
        makl_unset_var "HAVE_"`makl_upper $2`
        return 1
    fi
}

##\brief Check existence of a header.
##
##  Define HAVE_$2 if header \e $3 is found.
##  \e $1 determines whether the feature is optional or required.
##
##  \param $1 0:optional,1:required
##  \param $2 id of header
##  \param $3 header file
##  \param $* header files to include first
##
makl_checkheader ()
{
    [ -z `makl_get "__noconfig__"` ] || return

    opt=$1
    id=$2
    header=$3
    shift; shift; shift;
    tmpfile=${makl_run_dir}/snippet.c

    makl_info "checking for header ${id}"

    {
        for arg in $* ; do
            ${ECHO} "#include ${arg}"
        done
        ${ECHO} "#include ${header}"
        ${ECHO} "int main() { return 0; }"
    } > ${tmpfile}
    
    makl_compile_code 0 ${tmpfile}

    if [ $? -eq 0 ]; then
        makl_set_var "HAVE_"`makl_upper ${id}`
        return 0
    else
        [ ${opt} -eq 0 ] || makl_err 1 "failed check on required header ${id}!"
        makl_unset_var "HAVE_"`makl_upper ${id}`
        makl_warn "failed check on optional header ${id}"
        return 1
    fi
}

##\brief Check existence of a type.
##
##  Define HAVE_$1 if type \e $2 is found. 
##  \e $1 determines whether the feature is optional or required.
##  Extra includes can be listed in \e $*.
## 
##  \param $1 0:optional,1:required
##  \param $2 data type
##  \param $* includes
##
makl_checktype ()
{
    [ -z `makl_get "__noconfig__"` ] || return

    makl_info "checking for type $2"

    opt=$1
    type=$2
    shift
    shift
    tmpfile=${makl_run_dir}/snippet.c

    # substitute whitespace with underscores 
    def_type=`${ECHO} ${type} | sed 's/\ /_/g'`

    {
        for arg in $*; do
            ${ECHO} "#include ${arg}"
        done
        # on some systems (e.g. VxWorks) type checks are not picked up correctly
        # by the compiler, so force a check using sizeof() */
        ${ECHO} "
            int main() {
                ${type} x;
                return (sizeof(${type}) && 0);  
            }" 
    } > ${tmpfile}
    
    makl_compile_code 0 ${tmpfile}

    if [ $? -eq 0 ]; then
        makl_set_var "HAVE_"`makl_upper ${def_type}`
        return 0
    else
        [ ${opt} -eq 0 ] || makl_err 1 "failed check on required type ${type}!"
        makl_unset_var "HAVE_"`makl_upper ${def_type}`
        makl_warn "failed check on optional type $2"
        return 1
    fi
}

##\brief Check existence of an extern variable.
##
##  Define HAVE_$1 if the extern variable \e $2 is found. 
##  \e $1 determines whether the feature is optional or required.
## 
##  \param $1 0:optional,1:required
##  \param $2 extern variables
##  \param $* optional compilation flags
##
makl_checkextern()
{
    [ -z `makl_get "__noconfig__"` ] || return

    makl_info "checking for extern variable $2"

    opt=$1
    var=$2
    shift
    shift
    tmpfile=${makl_run_dir}/snippet.c

    # this fails when the linker doesn't find the variable in any linked
    # libraries
    ${ECHO} "
        extern void* ${var};
        int main() 
        {
            return (int) & ${var};
        }
        " > ${tmpfile}
    
    makl_compile_code 0 ${tmpfile} $*

    if [ $? -eq 0 ]; then
        makl_set_var "HAVE_"`makl_upper ${var}`
        return 0
    else
        [ ${opt} -eq 0 ] || \
            makl_err 1 "failed check on required extern variable ${var}!"
        makl_unset_var "HAVE_"`makl_upper ${var}`
        makl_warn "failed check on optional extern variable $2"
        return 1
    fi
}

##\brief Check existence of a symbol
##
##  Define HAVE_$2 if the symbol \e $2 is found. 
##  \e $1 determines whether the feature is optional or required.
##   
##  The symbol may be an external variable, function or a #define.
##   
##  \param $1 0:optional,1:required
##  \param $2 symbol
##  \param $* header files
##
makl_checksymbol()
{
    [ -z `makl_get "__noconfig__"` ] || return

    makl_info "checking for symbol $2"

    opt=$1
    var=$2
    shift
    shift
    tmpfile=${makl_run_dir}/snippet.c

    {
        for arg in $*; do
            ${ECHO} "#include ${arg}"
        done
        # this fails if the symbol is not defined (no #define, no variable, 
        # no function)
        ${ECHO} "
            #ifdef ${var}
            int main(){ return 0; }
            #else
            int main()
            {
                void *p = (void*)(${var});
                return 0;
            }
            #endif
            " 
    } > ${tmpfile}
    
    makl_compile_code 0 ${tmpfile}

    if [ $? -eq 0 ]; then
        makl_set_var "HAVE_"`makl_upper ${var}`
        return 0
    else
        [ ${opt} -eq 0 ] || makl_err 1 "failed check on required symbol ${var}!"
        makl_unset_var "HAVE_"`makl_upper ${var}`
        makl_warn "failed check on optional symbol ${var}"
        return 1
    fi
}

##\brief Check existence of an element in a struct
##
##  Define HAVE_$2_$3 if the element \e $3 exists in the struct \e $2
##  \e $1 determines whether the feature is optional or required.
##   
##  \param $1 0:optional,1:required
##  \param $2 type
##  \param $3 elem
##  \param $* header files
##
makl_checkstructelem()
{
    [ -z `makl_get "__noconfig__"` ] || return

    opt=$1
    type=$2
    elem=$3
    shift
    shift
    shift
    tmpfile=${makl_run_dir}/snippet.c

    def_type=`${ECHO} ${type} | sed 's/\ /_/g'`

    makl_info "checking for ${elem} in ${type}"

    {
        for arg in $*; do
            ${ECHO} "#include ${arg}"
        done
        # this fails if elem is not a field of the supplied type
        ${ECHO} "
            ${type} _a_;
            int main()
            {
                void *_p_ = (void*)(&(_a_.${elem}));
                return 0;
            }
            " 
    } > ${tmpfile}
    
    makl_compile_code 0 ${tmpfile}

    if [ $? -eq 0 ]; then
        makl_set_var "HAVE_"`makl_upper ${def_type}_${elem}`
        return 0
    else
        [ ${opt} -eq 0 ] || \
            makl_err 1 "failed check on required struct elem ${elem}!"
        makl_unset_var "HAVE_"`makl_upper ${def_type}_${elem}`
        makl_warn "failed check on optional struct elem ${elem}"
        return 1
    fi
}
