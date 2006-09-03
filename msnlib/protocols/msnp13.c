/** @file msnp13.c MSNP13 message handlers */
/*
 * Copyright (C) 2006 The aMSN Project
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <glib.h>
#include <glib/gprintf.h>

#include "../msn-connection.h"
#include "../msn-protocol.h"

static void CHG_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nCHG handler\n");
}


static void CHL_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nCHL handler\n");
}


static void FLN_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nFLN handler\n");
}


static void GCF_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nGCF handler\n");
}


static void ILN_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nINL handler\n");
}


static void MSG_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nMSG handler\n");
}


static void NLN_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nNLN handler\n");
}


static void QNG_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nQNG handler\n");
}


static void QRY_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nQRY handler\n");
}


static void RNG_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nRNG handler\n");
}


static void USR_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nUSR handler\n");
}


static void XFR_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nXFR handler\n");
  gchar **command_header = (gchar **) msn_message_get_command_header(message);
  if (g_str_equal(command_header[1], "NS")) {
    gchar **ns_address        = g_strsplit(command_header[2], ":", 2);
    gchar **redirected_server = g_strdup(ns_address[0]);
    gint    redirected_port   = (gint) g_ascii_strtod(ns_address[1], NULL);
    g_strfreev(ns_address);
  }
}


static void ANS_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nANS handler\n");
}


static void BYE_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nBYE handler\n");
}


static void CAL_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nCAL handler\n");
}


static void IRO_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nIRO handler\n");
}


static void JOI_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nJOI handler\n");
}


static void MSG_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nMSG handler\n");
}


static void USR_SB_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nUSR handler\n");
}


static void MSG_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  MsnConnectionType type = msn_connection_get_conn_type(conn);

  switch(type) {
    case MSN_CONNECTION_TYPE_DS:
    case MSN_CONNECTION_TYPE_NS:
      MSG_NS_handler(message, conn);
      break;
    case MSN_CONNECTION_TYPE_SB:
      MSG_SB_handler(message, conn);
      break;
  }
}


static MsnCommand CHG_command = {
  { .name        = "CHG" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = CHG_NS_handler
};

static MsnCommand CHL_command = {
  { .name        = "CHL" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = CHL_NS_handler
};

static MsnCommand CVR_command = {
  { .name        = "CVR" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = NULL
};

static MsnCommand FLN_command = {
  { .name        = "FLN" },
  .has_trid    = FALSE,
  .has_payload = FALSE,
  .handler     = FLN_NS_handler
};

static MsnCommand GCF_command = {
  { .name        = "GCF" },
  .has_trid    = TRUE,
  .has_payload = TRUE,
  .handler     = GCF_NS_handler
};

static MsnCommand ILN_command = {
  { .name        = "ILN" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = ILN_NS_handler
};

static MsnCommand MSG_command = {
  { .name        = "MSG" },
  .has_trid    = TRUE,
  .has_payload = TRUE,
  .handler     = MSG_handler
};

static MsnCommand NLN_command = {
  { .name        = "NLN" },
  .has_trid    = FALSE,
  .has_payload = FALSE,
  .handler     = NLN_NS_handler
};

static MsnCommand QNG_command = {
  { .name        = "QNG" },
  .has_trid    = FALSE,
  .has_payload = FALSE,
  .handler     = QNG_NS_handler
};

static MsnCommand QRY_command = {
  { .name        = "QRY" },
  .has_trid    = TRUE,
  .has_payload = FALSE, // Remember this is about server to client!
  .handler     = QRY_NS_handler
};

static MsnCommand RNG_command = {
  { .name        = "RNG" },
  .has_trid    = FALSE,
  .has_payload = FALSE,
  .handler     = RNG_NS_handler
};

static MsnCommand USR_command = {
  { .name        = "USR" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = USR_NS_handler
};

static MsnCommand XFR_command = {
  { .name        = "XFR" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = XFR_NS_handler
};

/* SB Commands */
static MsnCommand ANS_command = {
  { .name        = "ANS" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = ANS_SB_handler
};

static MsnCommand BYE_command = {
  { .name        = "BYE" },
  .has_trid    = FALSE,
  .has_payload = FALSE,
  .handler     = BYE_SB_handler
};

static MsnCommand CAL_command = {
  { .name        = "CAL" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = CAL_SB_handler
};

static MsnCommand IRO_command = {
  { .name        = "IRO" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = IRO_SB_handler
};

static MsnCommand JOI_command = {
  { .name        = "JOI" },
  .has_trid    = FALSE,
  .has_payload = FALSE,
  .handler     = JOI_SB_handler
};

static const MsnCommand *cmd_list[] = {
  &CHG_command,
  &CHL_command,
  &CVR_command,
  &FLN_command,
  &GCF_command,
  &ILN_command,
  &MSG_command,
  &NLN_command,
  &QNG_command,
  &QRY_command,
  &RNG_command,
  &USR_command,
  &XFR_command,
  &ANS_command,
  &BYE_command,
  &CAL_command,
  &IRO_command,
  &JOI_command,
  NULL
};

static const MsnProtocol protocol_msnp13 = {
  .name = "MSNP13",
  .cmd_list = cmd_list
};

const MsnProtocol *msn_protocol_init_msnp13(void) {
  static gboolean cvr_copied = FALSE;

  if(!cvr_copied) {
    /* Copy the CVR command info from CVR0
     *
     * This is a hack to avoid problems when the VER response is handled before
     * the CVR response (which is likely to happen).
     */
    MsnProtocol *protocol_cvr0 = msn_protocol_find("CVR0");
    MsnCommand *command_CVR_CVR0 = msn_protocol_find_command(protocol_cvr0, "CVR");
    MsnCommand *command_CVR_MSNP13 = msn_protocol_find_command(&protocol_msnp13, "CVR");
    g_assert(command_CVR_CVR0 != NULL && command_CVR_MSNP13 != NULL);
    command_CVR_MSNP13->has_trid    = command_CVR_CVR0->has_trid;
    command_CVR_MSNP13->has_payload = command_CVR_CVR0->has_payload;
    command_CVR_MSNP13->handler     = command_CVR_CVR0->handler;
    cvr_copied = TRUE;
  }

  return &protocol_msnp13;
}
