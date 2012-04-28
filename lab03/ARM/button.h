#include "stm32l1xx.h"

/* 
 * NAME
 * ----
 *
 * button.h
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
 *	}
 *
 *  if (button_released() {
 *		// do something else
 * 	}
 *
 *  // block until button is pressed
 *  // and released.
 *  wait_button_press();
 *
 */

void enable_button();

unsigned int button_pressed();

unsigned int button_released();

void wait_button_press();
