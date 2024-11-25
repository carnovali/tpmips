##################################################################################################################
##								##
## - TRABAJO FINAL ARQUITECTURA DE LAS COMPUTADORAS I - ##########################################################
## - Listas Enlazadas		            - ##########################################################
## - Lucas Carnovali                             2024 - ##########################################################
##								##
## ** Por un error en algun momento, el primer nodo agregado a una lista en lugar de tener su puntero al	##
##    siguiente apuntandose a si mismo, lo tiene inicializado en NULL. Esto cambia el comportamiento de algunas ## 
##    de las funciones **							##
##								##
##################################################################################################################

.data
slist:	.word 0 				# lista de bloques libres
cclist:	.word 0 				# lista de categorias
wclist:	.word 0 				# categoria actual 
schedv:	.space 32				# vector de funciones
menu:	.ascii "Colecciones de objetos categorizados\n"
	.ascii "====================================\n"
	.ascii "1-Nueva categoria\n"
	.ascii "2-Siguiente categoria\n"
	.ascii "3-Categoria anterior\n"
	.ascii "4-Listar categorias\n"
	.ascii "5-Borrar categoria actual\n"
	.ascii "6-Anexar objeto a la categoria actual\n"
	.ascii "7-Listar objetos de la categoria\n"
	.ascii "8-Borrar objeto de la categoria\n"
	.ascii "0-Salir\n"
	.asciiz "Ingrese la opcion deseada: "
error:	.asciiz "Error: "
invalidOptMsg:.asciiz "Opcion invalida\n"
notFound:	.asciiz "notFound\n"
return:	.asciiz "\n"
item:	.asciiz ">"
space:	.asciiz " "
catName:	.asciiz "\nIngrese el nombre de una categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria: "
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:	.asciiz "\nIngrese el nombre de un objeto: "
success:	.asciiz "La operación se realizo con exito\n\n"

.text
.globl main

## MAIN ##

main: 	
	jal	loadSchedv
	jal	showMenu
	
	j	end

##

## MEMORIA ##

# return: direccion de memoria de un bloque libre
smalloc:
	lw	$t0, slist
	beqz	$t0, sbrk				# lista == NULL ?
	move	$v0, $t0				# return en $v0
	
	# reubicar slist
	lw	$t0, 12($t0)
	sw	$t0, slist
	
	jr	$ra

# return: direccion de memoria de un bloque libre de 16 bytes	
sbrk: 
	li	$a0, 16
	li	$v0, 9
	syscall
	jr	$ra

# $a0: direccion de la memoria a liberar
sfree:
	lw	$t0, slist 				# $t0 = slist
	sw	$t0, 12($a0) 				# memoria a liberar(+12) = slist 
	sw	$a0, slist				# slist = memoria a liberar(+0)
	jr	$ra
	
##

## UTILS ##

# imprime el mensaje de error y su codigo
# $a0: codigo de error
printError:
	#inicio rutina
	addi	$sp, $sp, -8
	sw	$s0, 4($sp)
	sw	$ra, 8($sp)
	
	move	$s0, $a0
	
   	la	$a0, error
   	jal	printMsg
   	
   	move	$a0, $s0
   	li	$v0, 1
   	syscall
   	
   	la	$a0, return
 	jal	printMsg
   	
   	# fin rutina
   	lw	$s0, 4($sp)
   	lw	$ra, 8($sp)
	addi	$sp, $sp, 8
	jr	$ra


# imprimir mensajes (string)
# $a0: &mensaje-a-imprimir
printMsg:
	#inicio rutina
	addi	$sp, $sp, -4
	sw	$ra, 4($sp)
	
	# imprimir cadena
   	li	$v0, 4             
   	syscall
   	
   	# fin rutina
   	lw	$ra, 4($sp)
	addi	$sp, $sp, 4
	jr	$ra


# agrega un nodo a la lista
# a0: direccion de memoria de la lista
# a1: NULL si es categoria, id si es objeto
# a2: nombre para el nodo
# v0: direccion de memoria del nuevo nodo
addNode:
	addi	$sp, $sp, -8
	sw	$ra, 8($sp)
	
	sw	$a0, 4($sp)
	jal	smalloc 
	
	sw	$a1, 4($v0) 				# *nodo.id/lista-objeto = $a1
	sw	$a2, 8($v0)				# *nodo.nombre = $a2
	lw	$a0, 4($sp)
	lw	$t0, 0($a0)				# $t0 = &nodo-inicial
	beqz	$t0, addNodeEmptyList 			# &nodo-inicial == NULL ?
#agrega un nodo al final de la lista
addNodeToEnd:
	lw	$t1, 0($t0) 				# $t1 = &nodo-inicial.anterior
	# actualizar anterior y siguiente en el nodo actual
	sw	$t1, 0($v0) 				# *nodo-nuevo.anterior = &nodo-inicial
	sw	$t0, 12($v0)				# *nodo-nuevo.siguiente = &nodo-inicial.anterior
	# actualizar anterior y primer nodo al nuevo
	sw	$v0, 12($t1)				# *nodo-anterior.siguiente = &nodo-nuevo
	sw	$v0, 0($t0)				# *nodo-siguiente.anterior = &nodo-nuevo
	j	addNodeExit
#agrega un nodo cuando la lista esta vacia
addNodeEmptyList: 
	sw	$v0, 0($a0)				# *nodo-inicial = &nodo-nuevo
	sw	$v0, 0($v0)				# *nodo.anterior = &nodo-nuevo
	sw	$zero, 12($v0)			# *nodo.siguiente = NULL
addNodeExit:
	lw	$ra, 8($sp)
	addi	$sp, $sp, 8
	jr	$ra
	
	
# borra un nodo de la lista
# a0: direccion del nodo a borrar
# a1: direccion de la lista de donde borrar el nodo 
delNode:
	# inicio rutina
	addi	$sp, $sp, -8
	sw	$ra, 8($sp)
	sw	$a0, 4($sp)
	
	# borrar el nombre asociado al nodo
	lw	$a0, 8($a0)
	jal	sfree
	lw	$a0, 4($sp)
	
	lw	$t0, 12($a0)				# $t0 = &nodo-siguiente
# checar si es el unico nodo
node:
	beqz	$t0, delNodePointSelf			# nodo-siguiente == NULL ?
	lw	$t1, 0($a0)				# $t1 = &nodo-anterior
	sw	$t1, 0($t0)				# *nodo-siguiente.anterior = &nodo-anterior
	lw	$t2, 0($a1)				# $t2 = &primer-nodo
	lw	$t3, 12($t0)				# $t3 = nodo-siguiente.siguiente
	sw	$t0, 12($t1)				# *nodo-anterior.siguiente = &nodo-siguiente
again:
	# chequear si el nodo actual es el unico de la lista
	bne	$a0, $t2, delNodeExit
	sw	$t0, ($a1) 				# guarda el nodo como inicio de la lista 
	
	# chequear si existen solo 2 nodos en la lista
	beq	$t3, $a0, delNode2Elements			# nodo-siguiente.siguiente == nodo ?
	j	delNodeExit
delNode2Elements:
	sw	$zero, 12($t1)			# pone en NULL nodo-anterior.siguiente
	j	delNodeExit
delNodePointSelf:
	sw	$zero, ($a1)				# &lista = NULL
delNodeExit:
	jal	sfree
	lw	$ra, 8($sp)
	addi	$sp, $sp, 8
	jr	$ra


# scanf, pide al usuario un nombre lo guarda y devuelve su direccion de memoria
# a0: mensaje a imprimir
# return: direccion de memoria del bloque de memoria con el nombre
getBlock:
	# inicia rutina
	addi	$sp, $sp, -4
	sw	$ra, 4($sp)
	
	# imprime el mensaje
	li	$v0, 4
	syscall
	jal	smalloc				# asignar memoria para el nombre
	
	move	$a0, $v0				# $a0 = direccion de memoria nueva
	li	$a1, 16 				# maxima cant de caracteres
	li	$v0, 8
	syscall
	
	move	$v0, $a0 				# retorna la DM del nombre

	lw	$ra, 4($sp)
	addi	$sp, $sp, 4
	jr	$ra
  
## PROGRAMA ##

# inicializa el vector de funciones
loadSchedv:	
	la	$t0, schedv
	la	$t1, newCategory
	sw	$t1, 0($t0)
	la	$t1, nextCategory
	sw	$t1, 4($t0)
	la	$t1, prevCategory
	sw	$t1, 8($t0)
	la	$t1, listCategories
	sw	$t1, 12($t0)
	la	$t1, delCategory
	sw	$t1, 16($t0)
	la	$t1, newObject
	sw	$t1, 20($t0)
	la	$t1, listObjects
	sw	$t1, 24($t0)
	la	$t1, delObject
	sw	$t1, 28($t0)
	
	jr	$ra


# muestra el menu, pide una opcion, ejecuta la funcion con ese numero en schedv
showMenu:
	# imprimir menu
	la	$a0, menu
	li	$v0, 4
	syscall
	
	# leer opción ingresada por el usuario
    	li	$v0, 5
    	syscall
    	move	$t0, $v0				# $t0 = opcion elegida

	# validar que la opción este en el rango [0-8]
    	beqz	$t0, end				# si la opcion es 0 salir
    	blt	$t0, 0, invalidOption
    	bge	$t0, 9, invalidOption

	# cargar direccion de la funcion desde el vector schedev
   	subi	$t0, $t0, 1				# indexar a la opcioon a 0
   	la	$t1, schedv				# $t1 = &schedv
  	sll	$t2, $t0, 2				# $t2 = t0 * 4 (tamaño de una palabra)
  	add	$t3, $t1, $t2				# direccion de la entrada correspondiente
 	lw	$t4, 0($t3)         			# $t4 = direccion de la funcion

	# llamar a la funcion
 	jalr	$t4
  	j	showMenu				# volver al menu despues de ejecutar
invalidOption:
	la	$a0, invalidOptMsg
	jal	printMsg
	j	showMenu
	

## 1 - nueva categoria ##	
# agrega una categoria a la lista de categorias	
newCategory:
	# inicio rutina 
	addiu	$sp, $sp, -8
	sw	$s0, 4($sp)
	sw	$ra, 8($sp)
	
	# scanf
	la	$a0, catName
	jal	getBlock
	
	# agregar el nodo con el nuevo nombre a la lista
	la	$a0, cclist				# $a0 = &lista
	li	$a1, 0 				# $a1 = NULL
	move	$a2, $v0 				# $a2 = &nombre
	jal	addNode
	
	# comprueba si ya existe una categoria seleccionada, si no, setea el nuevo nodo a serlo
	move	$s0, $v0				# $s0 = &nuevo-nodo
	lw	$t0, wclist				# $t0 = &categoria-seleccionada
	bnez	$t0, newCategoryEnd			# $t0 == NULL ?
	sw	$s0, wclist 				# *categoria-seleccionada = &nuevo-nodo

	# imprime nombre nuevo nodo
	la	$a0, selCat
	jal	printMsg
	lw	$a0, 8($s0)
	jal	printMsg
newCategoryEnd:
	li	$v0, 0 				# return success
	lw	$s0, 4($sp)
	lw	$ra, 8($sp)
	addiu	$sp, $sp, 8
	jr	$ra


## 2 A - proxima categoria ##
# mueve wclist a la proxima categoria
nextCategory:	
	# inicio rutina
	addi	$sp, $sp, -4
	sw	$ra, 4($sp)
		
	# cargar la categoria actual y chequear que exista
	lw	$t0, wclist          			# $t0 = &categoria-inicial
	li	$a0, 201
	beqz	$t0, nextCategoryError 			# categoria-inicial == NULL ?

	# cargar el siguiente nodo y chequear que exista
	lw	$t1, 12($t0)         			# $t1 = categoria-actual.siguiente
	li	$a0, 202
	beqz	$t1, nextCategoryError 			# categoria-siguiente == NULL ?

	# actualizar wclist para que apunte a la siguiente categoria
	sw	$t1, wclist          			# wclist = nodo-actual.siguiente
	
	# imprimir mensaje
	la	$a0, selCat
	jal	printMsg
	lw	$a0, 8($t1)
	jal	printMsg
	j	nextCategoryEnd
nextCategoryError:
	jal	printError
nextCategoryEnd:
	lw	$ra, 4($sp)
	addi	$sp, $sp, 4
	jr	$ra
	

## 2 B - anterior categoria ##
# mueve wclist a la anterior categoria
prevCategory:	
	# inicio rutina
	addi	$sp, $sp, -4
	sw	$ra, 4($sp)

	# carga la categoria actual y compruba que exista
	lw	$t0, wclist				# $t0 = &categoria-actual
	li	$a0, 201
	beqz	$t0, prevCategoryError

	# carga la categoria siguiente y chequea que exista
	lw	$t1, 12($t0)         			# $t1 = nodo-actual.siguiente
	li	$a0, 202
	beqz	$t1, prevCategoryError 			

	# actualizar wclist para que apunte al siguiente nodo
	lw	$t1, 0($t0)
	sw	$t1, wclist          			# wclist = nodo-actual.siguiente
	
	# imprimir nombre de la categoria seleccionada
	la	$a0, selCat
	jal	printMsg
	lw	$a0, 8($t1)
	jal	printMsg
	j	prevCategoryEnd
prevCategoryError:
	jal	printError
prevCategoryEnd:
	lw	$ra, 4($sp)
	addi	$sp, $sp, 4
	jr	$ra


## 3 - listar categorias ##
# imprime todas las categorias de las lista de categorias	
listCategories:
	# inicio rutina
	addi	$sp, $sp, -12
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$ra, 12($sp)
	
	# carga la primer categoria de la lista y comprueba que exista
	lw	$s0, cclist				# $s0 = &categoria-inicial
	li	$a0, 301
	beqz	$s0, listCategoriesError
	
	move	$s1, $s0				# $s1 = &categoria-inicial

# recorre la lista en loop e imprime los elementos siempre que (exista nodo.sig && nodo.sig != nodo inicial)
listCategoriesLoop:
	# imprime el nombre de la categoria
	la	$a0, item
	jal	printMsg
	lw	$a0, 8($s1)
	jal	printMsg
	
	# avanza a la proxima categoria y chequea que exista
	lw	$s1, 12($s1)				# actualiza nodo-actual a nodo-actual.siguiente
	beqz	$s1, listCategoriesEnd			# nodo-sigiente == NULL ?
	beq	$s0, $s1, listCategoriesEnd			# categoria-inicial == nodo-siguiente ?
	
	j	listCategoriesLoop
listCategoriesError:
	jal	printError
listCategoriesEnd:
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$ra, 12($sp)
	addi	$sp, $sp, 12
	jr	$ra

## 4 - borrar categoria ##
# borra la categoria seleccionada
delCategory:	
	# inicio rutina
	addi	$sp, $sp, -12
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$ra, 12($sp)
	
	# carga la categoria seleccionada y comprueba que exista (501)
	lw	$s0, wclist				# $s0 = &categoria-seleccionada
	li	$a0, 401
	beqz	$s0, delCategoryError
	
	# carga la lista de objetos asociada a esa categoria y los elimina 1 por 1
	la	$a0, 4($s0)				# $a0 = &categoria-inicial
	jal	clearList
	
	# chequea que exista otra categoria en la lista
	lw	$t0, 12($s0)				# $t0 = categoria.siguiente
	la	$t1, wclist				# $t1 = &categoria-seleccionada
	beqz	$t0, noNextCategory			# categoria.siguiente == NULL ?
	sw	$t0, 0($t1)				# wclist = categoria.siguiente
	j	delCategoryNode
# si es la unica categoria
noNextCategory:
	sw	$zero, 0($t1)				# categoria-seleccionada = NULL
	
# borra el nodo de la categoria seleccionada
delCategoryNode:
	move	$a0, $s0				# $a0 = &categoria-seleccionada
	la	$a1, cclist				# $a1 = &lista
	jal	delNode
	j	delCategorySuccess
delCategoryError:
	jal	printError
	j	delCategoryEnd
delCategorySuccess:
	la	$a0, success
	jal	printMsg
delCategoryEnd:
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$ra, 12($sp)
	addi	$sp, $sp, 12
	jr	$ra
	
# borra todos los objetos ascociados a la categoria seleccionada
# a0: direccion del primer nodo de la lista
clearList:
	# inicio rutina
    	addi	$sp, $sp, -16
    	sw	$s0, 4($sp)
    	sw	$s1, 8($sp)
    	sw	$s2, 12($sp)
    	sw	$ra, 16($sp)

	# comprueba si la lista es NULL
    	lw	$s0, 0($a0)       			# $s0 = &primer-nodo
    	beqz	$s0, clearListEnd

	move	$s2, $a0				# $s2 = &lista-objetos
# recorre la lista eliminando uno a uno los elementos hasta que nodo.sig == NULL
clearListLoop:
    	lw	$s1, 12($s0)				# $s1 = *nodo.sig
    	
    	# eliminar el nodo actual
    	move	$a0, $s0           			# $a0 = &nodo-actual
    	move	$a1, $s2          			# $a1 = &lista-objetos
    	jal	delNode

	#chequea que exista el siguiente nodo
    	beqz	$s1, clearListEnd			# nodo-siguiente == NULL ?
    	move	$s0, $s1           			# $s0 = &nodo-siguiente
    	j	clearListLoop
clearListEnd:
    	sw	$zero, 0($a0)      			# poner la lista como NULL
    	lw	$s0, 4($sp)
    	lw	$s1, 8($sp)
    	lw	$s2, 12($sp)
    	lw	$ra, 16($sp)
    	addi	$sp, $sp, 16
    	jr	$ra


## 5 - nuevo objeto ##
# crea un objeto dentro de la categoria seleccionada
newObject:
	# inicio rutina
	addi	$sp, $sp, -4
	sw	$ra, 4($sp)
	
	# carga la categoria seleccionada y comprueba que exista (501)
	lw	$t0, wclist				#$t0 = &categoria-seleccionada
	li	$a0, 501
	beqz	$t0, newObjectError
	
	# pide al usuario el nombre del nuevo objeto
	la	$a0, objName
	jal	getBlock
	move	$a2, $v0				# $a2 = nombre del objeto
	
	# carga la lista donde agregar el objeto y consigue su id correspondiente
	lw	$t0, wclist
	la	$a0, 4($t0)				# $a0 = &primer-objeto
	jal	getObjectId
	move	$a1, $v0				# $a1 = id del nuevo nodo
	jal	addNode				# agrega el nodo
	j	newObjectSuccess
newObjectError:
	jal	printError
	j	newObjectEnd
newObjectSuccess:
	la	$a0, success
	jal	printMsg
newObjectEnd:
	lw	$ra, 4($sp)
	addi	$sp, $sp, 4
	jr	$ra

# devuelve la ultima id de una lista de objetos + 1 (id para nuevo ovjeto)
# return - id del proximo nodo a agregar
getObjectId:
	# inicio rutina
	addi	$sp, $sp, -16
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$ra, 16($sp)
	
	# carga el primer elemento de la lista y comprueba que exista (301)
	lw	$s0, wclist				# $s0 = &objeto-inicial
	beqz 	$s0, getObjectIdError
	li	$s2, 0				# id inicial
	lw	$s0, 4($s0)				# carga el primer objeto de esa categoria
	beqz	$s0, getObjectIdEnd
	
	move	$s1, $s0				# $s1 = &objeto-inicial
	
# recorre la lista en loop siempre que (exista nodo.sig && nodo.sig != nodo inicial)
getObjectIdLoop:
	lw	$s2, 4($s1)				# $s2 = id objeto actual
	lw	$s1, 12($s1)				# avanza objeto-actual a objeto-actual.siguiente
	beqz 	$s1, getObjectIdEnd			# objeto-siguiente == NULL ?
	beq	$s0, $s1, getObjectIdEnd			# objeto-inicial == objeto-siguiente ?

	j	getObjectIdLoop
getObjectIdError:
	la	$a0, invalidOptMsg
	jal	printError
getObjectIdEnd:
	addi	$s2, $s2, 1				# id = id del ultimo objeto + 1
	move 	$v0, $s2				# return = id nuevo nodo
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, 16
	jr	$ra


## 6 - listar objetos ##
## imprime los nombres de todos los objetos de una categoria	
listObjects:
	# inicio rutina
	addi	$sp, $sp, -12
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$ra, 12($sp)
	
	# carga el primer elemento de la lista y comprueba que exista
	lw	$s0, wclist				# $s0 = &categoria-seleccionada
	li	$a0, 601
	beqz	$s0, listObjectError
	
	# carga el primer objeto de la categoria y comprueba que exista
	lw	$s0, 4($s0)				# $s0 = &primer-objeto de la categoria
	li	$a0, 602
	beqz	$s0, listObjectError
	
	move	$s1, $s0				# $s1 = &objeto-inicial
	
# recorre la lista en loop e imprime los objetos hasta llegar al ultimo
listObjectsLoop:
	# imprimir id y nombre de objeto
	la	$a0, item
	jal	printMsg
	lw	$a0, 4($s1)				# $a0 = id del objeto
	li	$v0, 1
	syscall
	la	$a0, space
	jal	printMsg
	lw	$a0, 8($s1)				# $a0 = nombre del objeto
	jal	printMsg
	
	# mover al siguiente nodo y siempre que nodo.siguiente (!= NULL && != nodo inicial)
	lw	$s1, 12($s1)				# avanza el nodo actual a nodo.siguiente
	beqz	$s1, listObjectsEnd			# nodo-siguiente == NULL ?
	beq	$s0, $s1, listObjectsEnd			# primer-objeto == nodo-siguiente ?
	
	j	listObjectsLoop
listObjectError:
	jal	printError
listObjectsEnd:
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$ra, 12($sp) 
	addi	$sp, $sp, 12
	jr	$ra


## 7 - borrar objeto ##
# pide al usuario un nro de id y borra el objeto asociado a ese id dentro de la categoria seleccionada
delObject:
	# inicio rutina
	addi	$sp, $sp, -4
	sw	$ra, 4($sp)
	
	# leer opcion ingresada por el usuario
	la	$a0, idObj
	jal	printMsg
    	li	$v0, 5
    	syscall
    	move	$t0, $v0				# $t0 = opcion ingresada
	
	# validar que la opcion sea > 0
    	blt	$t0, 1, delObjectNotFound
    	
    	# chequear que exista una categoria actual
    	lw	$t1, wclist				# $t1 = &categoria-actual
	li	$a0, 701
	beqz	$t1, delObjectError
	
	# chequear que exista almenos un objeto
	la	$t3, 4($t1)				# $t3 = &lista-objetos
	lw	$t1, 0($t3)				# $t1 = &objeto-inicial
	li	$a0, 702
	beqz	$t1, delObjectError
	
	move	$t2, $t1				# $t2 = &objeto-inicial

# recorre toda la lista hasta encontrar un objeto cuyo id == id ingresado
delObjectLoop:
	lw	$t4, 4($t1)				# $t4 = objeto-actual.id
	beq	$t4, $t0, delObjectFound			# objeto-actual.id == opcion ingresada ?
	lw	$t1, 12($t1)				# avanzo objeto-actual a objeto-actual.siguiente
	beq	$t1, $t2, delObjectNotFound			# objeto-siguiente == primer-objeto ?
	
	j	delObjectLoop

# el id ingresado no corresponde a ningun objeto de la lista
delObjectNotFound:
	la	$a0, notFound
    	jal	printMsg
    	j	delObjectEnd

# se encontro un objeto con el id == id ingresado
delObjectFound:
	move	$a0, $t1				# $a0 = &objeto-actual
	move	$a1, $t3				# $a1 = &lista-objetos
	jal 	delNode				# elimina el nodo
delObjectSuccess:
	la	$a0, success
	jal	printMsg
	j	delObjectEnd
delObjectError:
	jal	printError
delObjectEnd:
    	lw	$ra, 4($sp)
    	addi	$sp, $sp, 4
    	jr	$ra

##

# finaliza el programa
end:	
	li	$v0, 10
	syscall
