#include "stm32l1xx.h"

/* 
 * enable_button(), button_pressed()
 *
 * The STM32L Discovery contains a USER button.
 * This functions enables it so it can be tested
 * to see if it is pressed or not.
 *
 * SYNOPSIS
 * --------
 *
 *  enable_button();
 *
 *	if (button_pressed()) {
 *		// do something
 *	} else {
 *		// do something else
 * 	}
 */

void enable_button();

unsigned int button_pressed();
