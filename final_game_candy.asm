	.data
	#hier worden de verschillende elementen een kleur toegewezen, deze worden later gebruikt in de table
	wall:			.word	0x0000ff	#blauw
	passage:		.word	0x000000	#zwart, staat in deze lijst omdat er anders een uitzonderlijk geval is
	player_position:	.word	0xffff00	#geel
	exit_location:		.word	0x00ff00	#groen
	enemy:			.word	0xff0000	#rood
	candy:			.word	0xffffff	#wit
	
	
	#filename bevat het datapad naar het element dat we zullen inlezen
	filename:
		.asciiz "input.txt" 	#file name, file moet in dezelfde map staan als .jar bestand
	
	#buffer bevat de locatie in het geheugen waar we de inhoud van het bestand zullen opslaan voor gebruik in het programma
	buffer:
		.space 2048

	#we maken een table van de verschillende inputs, nut hiervan wordt duidelijk in de input loop
	#newline staat niet in de lijst omdat het hetzelfde effect heeft als elk ander karakter (niets)
	inputs: 
		.ascii		"w", "p", "s", "u", "e", "c", "\n"
	
	#door de elementen in de zelfde volgorde in een corresponderende table te zetten kunnen we in het programma dezelfde offset gebruiken
	#weliswaar door deze met 4 te vermenigvuldigen (deze tabel bestaat uit words)
	elements:
		.word		wall, passage, player_position, exit_location, enemy, candy, newline
	
	#de verschillende input mogelijkheden
	up:	.ascii	"z"
	down:	.ascii	"s"
	left:	.ascii	"q"
	right:	.ascii	"d"
	exit_char:	.ascii "x"
	
	#text die verschijnt als men wint
	victorymessage:	.asciiz	"\nHoera, je hebt gewonnen!!!"
	
	#het ingelezen karakter wordt tijdelijk in het geheugen opgeslagen
	inputchar:	.space 3
	
	#we vragen om input:
	askInput:	.asciiz "Geef een karakter: q: naar links, s: naar onder, d: naar rechts, z: naar boven, x: spel eindigen.\n"
	
.text
#het main programma
main:
	la $a0, filename
	jal create_maze
	move $s7, $v0
	
	lw $a0, player_position #laad de waarde van de positie van de speler in het eerste argument
	jal find_special_loc	#zoek de speler in het speelveld
	move $s0, $v0	#laad de rij van de speler in $s0
	move $s1, $v1	#laad de kolom van de speler in $s1
	
	li $s2, 0	#laad de geheugenlocatie in $s2
	
	li $v0, 4
	la $a0, askInput
	syscall
	
	while_loop:
		bgtz $s7, still_candy
		bltz $s7, still_candy #er is dan wel geen snoep meer maar we moeten de exit niet meer toe voegen
		jal add_exit
		move $s2, $v0
		still_candy:
		move $a0, $s0	#laad de rij van de speler in het eerste argument
		move $a1, $s1	#laad de kolom van de speler in het tweede argument 
		jal get_memory_coordinates	#haal de geheugenlocatie van de coordinaten op
		move $t0, $v0	#laad  de geheugenlocatie in $t0
		beq $t0, $s2, win	#indien we op de exit belandt zijn gaan we naar win
		
		#lees een char
		li $v0, 8
		la $a0, inputchar
		li $a1, 2
		syscall
		lbu $s3, inputchar
		
		lbu $t0, up
		beq $s3, $t0, goUp
		
		lbu $t0, down
		beq $s3, $t0, goDown
		
		lbu $t0, left
		beq $s3, $t0, goLeft

		lbu $t0, right
		beq $s3, $t0, goRight
				
		lbu $t0, exit_char
		beq $s3, $t0, exit
		j while_loop		
		goUp:
			#laad rij en kolom in de argumenten
			move $s5, $s0	#rij
			move $s6, $s1	#kolom
			
			#voer de aanpassing op de locatie uit
			addi $s0, $s0, -1	#verlaag de rij met 1 -> up
			
			#laad nieuwe rij en kolom in de argumenten
			move $a2, $s0
			move $a3, $s1
			j continue
		goDown:
			#laad rij en kolom in de argumenten
			move $s5, $s0	#rij
			move $s6, $s1	#kolom
			
			#voer de aanpassing op de locatie uit
			addi $s0, $s0, 1	#verhoog de rij met 1 -> down
			
			#laad nieuwe rij en kolom in de argumenten
			move $a2, $s0
			move $a3, $s1
			j continue
		goLeft:
			#laad rij en kolom in de argumenten
			move $s5, $s0	#rij
			move $s6, $s1	#kolom
			
			#voer de aanpassing op de locatie uit
			addi $s1, $s1, -1	#verlaag de kolom met 1 -> left
			
			#laad nieuwe rij en kolom in de argumenten
			move $a2, $s0
			move $a3, $s1
			j continue
		goRight:
			#laad rij en kolom in de argumenten
			move $s5, $s0	#rij
			move $s6, $s1	#kolom
			
			#voer de aanpassing op de locatie uit
			addi $s1, $s1, 1	#verhoog de kolom met 1 -> right
			
			#laad nieuwe rij en kolom in de argumenten
			move $a2, $s0
			move $a3, $s1
			j continue
	
		continue:
			#we kijken wat er op deze locatie staat
			move $a0, $s0
			move $a1, $s1
			jal get_memory_coordinates
			move $t1, $v0
			
			#indien we snoep vinden is er een snoep minder in het spel
			lw $t2, ($t1)
			bne $t2, 0xffffff, no_candy_here
			subi $s7, $s7, 1
			
			no_candy_here:
			move $a0 $s5
			move $a1, $s6
			jal update
			#zet de coordinaten op de actuele waarde
			move $s0, $v0
			move $s1, $v1
			j while_loop
win:
	li $v0, 4
	la $a0, victorymessage
	syscall

exit:
	li $v0, 10
	syscall



############################################################################################################
#Begin functie to create_maze

#$a0 = pad naar het bestand

#$v0 = aantal snoepen in het spel

create_maze:
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 24 #wijs 24 bytes toe aan de stack
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	sw $s2, -16($fp)
	sw $s3, -20($fp)
	
	move $s0, $a0	#het eerste argument is de pad naar het bestand
	
	#open het bestand en gebruik $s2 als descriptor
	li $v0, 13
	li $a1, 0
	li $a2,0
	move $a0, $s0
	syscall
	move $s1, $v0
	
	#schrijf de inhoud naar de geheugenplaats van buffer
	li $v0, 14
	move $a0, $s1
	la $a1, buffer
	li $a2, 2048
	syscall
	
	#sluit het bestand/textfile
	li $v0, 16
	move $a0, $s1
	syscall
	
	li $t6, 0	#$t6 zal de x coordinaat bijhouden
	li $t7, 0	#$t7 zal de y coordinaat bijhouden
	li $s2, 0
	li $t0, -1	#we zetten de offset hier op -1 omdat we voordat we hem het eerste maal gebruiken al verhogen met een
	loopmaze:
		addi $t0, $t0, 1	#we verhogen de offset met 1 (een char is een byte)
		addi $t6, $t6, 1	#we verhogen de x coordinaat met 1
		
		lbu $t1, buffer($t0) 		#we laden het karakter uit de ingelezen informatie
		beq $t1, $zero, exitmaze	#indien het karakter het einde van de stream aangeeft verlaten we de functie
		
		li $t3, -1 	#$t3 is de offset van de table inputs		
		inputloop:
		
			addi $t3, $t3, 1
			lbu $t4, inputs($t3)	#we laden de locatie van een mogelijke input in, die we dan vergelijken met de reele input
			beq $t1, $t4, colorassignment	#we gaan naar de code waar we de kleur toewijzen aan deze locatie
			beq $t3, 5, checknewline
			j inputloop
			
			
		colorassignment:	#wordt enkel aangeroepen indien men een kleur moet storen
		
			mul $t3, $t3, 4	#deze vermenigvuldiging is nodig om het overeenkomstige element te bekomen in de 2de tabel
			lw  $t5, elements($t3)
			lw $t5, ($t5)  #hoewel deze load vreemd lijkt is hij nodig om de kleur te krijgen en niet een verwijzing naar een kleur 
			beq $t5, 0xffffff, candy_found
			bne $t5, 0x00ff00, not_exit
			li $t5, 0x000000
			j not_exit	#anders tellen we een snoep te veel
			candy_found:
			addi $s3, $s3, 1
			not_exit:
			add $t8, $s2, $gp
			sw $t5, ($t8)
			addi $s2, $s2, 4 #we gebruiken een saved register om duidelijk te maken dat deze waarde doorheen de functie moet bewaard blijven
			j loopmaze
		
		#newline wordt apart van de rest gehouden omdat het niets stored naar het gehuegen, het is anders dan de andere inputs
		checknewline:
			addi $t3, $t3, 1
			lbu $t4, inputs($t3)	#we laden de locatie van een newline, die we dan vergelijken met de reele input
			beq $t1, $t4, newline
			j loopmaze
		
		newline:
			li $t6, 0		#de x-coordinaat wordt gereset naar 0
			addi $t7, $t7, 1	#de y-coordinaat wordt met een verhoogt
			j loopmaze
	
	#hier herladen we de oude waarden en keren we terug naar het main programma
	exitmaze:
		move $v0, $s3
		
		lw $ra, -4($fp)
		lw $s0, -8($fp)
		lw $s1, -12($fp)
		lw $s2, -16($fp)
		lw $s3, -20($fp)
		move $sp, $fp
		lw $fp, ($sp)
		jr $ra
########################################################################################################################################################################

########################################################################################################################################################################
#Begin functie Update player position

#$a0 = oude rij coordinaat
#$a1 = oude kolom coordinaat
#$a2 = nieuwe rij coordinaat
#$a3 = nieuwe kolom coordinaat

#$v0 = actuele rij positie van de speler
#$v1 = actuele kolom positie van de speler

update:
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 24
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	sw $s2, -16($fp)
	sw $s3, -20($fp)
	
	move $s0, $a0	#current player row
	move $s1, $a1	#current player column
	move $s2, $a2	#new player row
	move $s3, $a3	#new player column
	
	#we laden de geheugenlocatie van de nieuwe positie in $t3
	move $a0, $s2
	move $a1, $s3
	jal get_memory_coordinates
	move $t3, $v0
	
	lw $t4, ($t3)	#we laden in $t4 de kleur van de nieuwe positie 
	lw $t5, wall	#we laden de waarde van een muur in
	beq $t4, $t5, dont_change	#indien de nieuwe positie een muur is kan men er niet naar toe bewegen
	
	lw $t6, player_position
	sw $t6, ($t3)
	
	move $a0, $s0
	move $a1, $s1
	jal get_memory_coordinates
	move $t3, $v0
	
	lw $t6, passage
	sw $t6, ($t3)
	
	
	move $v0, $s2	#laad de nieuwe rij in $v0
	move $v1, $s3	#laad de nieuwe kolom in $v1
	j exitfunctieupdate
	
	dont_change:
		move $v0, $s0	#laad de oude rij in $v0
		move $v1, $s1	#laad de oude kolom in $v1
	
	exitfunctieupdate:
	
	lw $ra, -4($fp)
	lw $s0, -8($fp)
	lw $s1, -12($fp)
	lw $s2, -16($fp)
	lw $s3, -20($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra
	
#################################################################################################################################################################################

########################################################################################################################################
#begin hulpfunctie om een speler te vinden

#$a0 = de waarde van wat we zoeken, bv de waarde van player_position

#$v0 = de rij van de speler 
#$v1 = de kolom van de speler
find_special_loc:
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 20
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	sw $s2, -16($fp)
	
	li $s0, 0	#we beginnen vanaf de 0de rij te zoeken
	li $s1, 0	#we beginnen vanaf de 0de kolom te zoeken
	move $s2, $a0	#laad de waarde die op de speler positie staat in $t3
	loc_loop:
		move $a0, $s0	#laad de momentele rij in het eerste argument
		move $a1, $s1	#laad de momentele kolom in het tweede argument
		jal get_memory_coordinates	#haal het geheugenadres op
		lw $t2, ($v0)	#laad meteen de waarde op dit adres in $t2
		
		
		beq $t2, $s2, found	#indien de waarde overeenkomt met die van de positie van speler hebben we de speler gevonden
		addi $s1, $s1, 1	#ga naar de volgende kolom
		blt $s1, 32, loc_loop	#zolang het kolomnummer onder 8 blijft kunnen we gewoon de loop terug doorlopen
		li $s1, 0		#zet de kolom terug op 0
		addi $s0, $s0, 1	#ga naar de volgende rij
		j loc_loop
	
	found:
		move $v0, $s0
		move $v1, $s1
	
		lw $ra, -4($fp)
		lw $s0, -8($fp)
		lw $s1, -12($fp)
		lw $s2, -16($fp)
		move $sp, $fp
		lw $fp, 0($sp)
		jr $ra

#################################################################################################################################################################################	
			
#################################################################################################################################################################################
#hulpfunctie om geheugenlocatie te krijgen

#$a0 = rij coordinaat
#$a1 = kolom coordinaat

#$v0 = geheugenlocatie van de coordinaten

get_memory_coordinates:
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 16
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	
	move $s0, $a0	#laad rij
	move $s1, $a1	#laad kolom
	
	mul $t0, $s0, 32
	add $t1, $s1, $t0
	sll $t2, $t1, 2
	add  $t3, $gp, $t2
	
	move $v0, $t3
	
	
	lw $ra, -4($fp)
	lw $s0, -8($fp)
	lw $s1, -12($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra
	
########################################################################################################################################
#de functie add_exit die de exit toevoegd

#$v0 = geheugenlocatie van exit
#################################################################################################################################
add_exit:
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 16
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	
	li $s0, 0
	li $t0, 3
	lbu $t1, inputs($t0)
	loop_add_exit:
		lbu $s1, buffer($s0)
		beq $s1, $t1, found_exit
		addi $s0, $s0, 1
		j loop_add_exit
	found_exit:
		subi $s0, $s0, 4 
		sll $t2, $s0, 2
		add $t3, $gp, $t2
		li $t2, 0x00ff00
		sw $t2, ($t3)
	
	lw $a0, exit_location #laad de waarde van de positie van van de exit in het eerste argument
	jal find_special_loc	#zoek de speler in het speelveld
	move $a0, $v0	#laad de rij van de speler in $a0
	move $a1, $v1	#laad de kolom van de speler in $a1
	jal get_memory_coordinates
	move $v0, $v0	#laad de geheugenlocatie in $v0
	
	li $t0, 0x00ff00
	sw $t0, ($v0)
	
	lw $ra, -4($fp)
	lw $s0, -8($fp)
	lw $s1, -12($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra
	

