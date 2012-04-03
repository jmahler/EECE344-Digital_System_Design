#include "stm32l1xx.h"

/* 
 * NAME
 * ----
 *
 * enable_button(), button_pressed()
 *
 * DESCRIPTION
 * -----------
 *
 * The STM32L Discovery contains a USER button.
 * These functions enable it and then allow it
 * to be tested to see if it pressed or not.
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
