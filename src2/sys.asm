
extern
         #inc_h "memory"
pgfree   #syscall lmem,pgfree_
pgalloc  #syscall lmem,pgalloc_

         #inc_h "service"
quitapp  #syscall lser,quitapp_

         #inc_h "string"
pet2asc  #syscall lstr,pet2asc_  ;If needed for strings

