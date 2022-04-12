diff -ur bfm-0.6.1.orig/README bfm-0.6.1/README
--- bfm-0.6.1.orig/README	2003-10-11 03:29:08.000000000 -0500
+++ bfm-0.6.1/README	2003-11-01 20:59:22.000000000 -0600
@@ -7,7 +7,6 @@
 
 
 TODO
-- Any way to fix the update speed? Gkrellm maximum update is 10 per second.
 - Someone tests/does the FreeBSD and SunOS platform?
 - Possible/Make more sense, to make a gkrellm swallow plugin?
   (Quick search on google:
diff -ur bfm-0.6.1.orig/gkrellm-bfm.c bfm-0.6.1/gkrellm-bfm.c
--- bfm-0.6.1.orig/gkrellm-bfm.c	2003-11-01 10:44:15.000000000 -0600
+++ bfm-0.6.1/gkrellm-bfm.c	2003-11-01 20:58:57.000000000 -0600
@@ -68,6 +68,8 @@
 static Chart *chart = NULL;
 static ChartConfig *chart_config = NULL;
 
+static gint	timeout_id,
+			update_interval;
 
 
 /* From the actual bfm */
@@ -92,13 +94,13 @@
 GtkWidget *clock_check = NULL;
 GtkWidget *fish_traffic_check = NULL;
 
-static void
+static gboolean
 update_plugin(void)
 {
 	GdkEventExpose event;
 	gint ret_val;
 	gtk_signal_emit_by_name(GTK_OBJECT(chart->drawing_area), "expose_event", &event, &ret_val);
-
+	return TRUE;	/* restart timer */
 }
 
 
@@ -154,6 +156,15 @@
 	return TRUE;
 }
 
+
+static void
+disable_plugin(void)
+	{
+	if (timeout_id)
+		gtk_timeout_remove(timeout_id);
+	timeout_id = 0;
+	}
+
 static void
 create_plugin(GtkWidget *vbox, gint first_create)
 {
@@ -182,7 +193,10 @@
 				"leave_notify_event", GTK_SIGNAL_FUNC(leave_notify_event),
 				NULL);
 	}
-
+	if (!timeout_id)
+		timeout_id = gtk_timeout_add(1000 / update_interval,
+					(GtkFunction) update_plugin, NULL);
+	gkrellm_disable_plugin_connect(mon, disable_plugin);
 }
 
 
@@ -240,6 +254,44 @@
 	gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(fish_traffic_check), fish_traffic);
 }
 
+
+static void
+cb_interval_modified(GtkWidget *widget, GtkSpinButton *spin)
+	{
+	update_interval = gtk_spin_button_get_value_as_int(spin);
+	if (timeout_id)
+		gtk_timeout_remove(timeout_id);
+	timeout_id = gtk_timeout_add(1000 / update_interval,
+					(GtkFunction) update_plugin, NULL);
+	}
+
+static gchar	*pending_prog;
+
+static void
+cb_prog_entry(GtkWidget *widget, gpointer data)
+{
+	gboolean	activate_sig = GPOINTER_TO_INT(data);
+	gchar		*s           = gkrellm_gtk_entry_get_text(&prog_entry);
+
+	if (activate_sig)
+		{
+		gkrellm_dup_string(&prog, s);
+		g_free(pending_prog);
+		pending_prog = NULL;
+		}
+	else	/* "changed" sig, entry is pending on "activate" or config close */
+		gkrellm_dup_string(&pending_prog, s);
+}
+
+static void
+config_destroyed(void)
+	{
+	if (pending_prog)
+		gkrellm_dup_string(&prog, pending_prog);
+	g_free(pending_prog);
+	pending_prog = NULL;
+	}
+
 static void
 create_plugin_tab(GtkWidget *tab_vbox)
 {
@@ -287,10 +339,7 @@
 		"   fish swiming from right to left represents incoming traffic)\n",
 		"- Cute little duck swimming...\n",
 		"- Clock hands representing time (obviously)...\n",
-		"- Click and it will run a command for you (requested by Nick =)\n\n",
-		"<i>Notes\n\n",
-		"- Currently Gkrellm updates at most 10 times a second, and so\n",
-		"  BFM updates is a bit jerky still.\n",
+		"- Click and it will run a command for you (requested by Nick =)\n",
 		"\n\n",
 	};
 
@@ -307,6 +356,8 @@
 	tabs = gtk_notebook_new();
 	gtk_notebook_set_tab_pos(GTK_NOTEBOOK(tabs), GTK_POS_TOP);
 	gtk_box_pack_start(GTK_BOX(tab_vbox), tabs, TRUE, TRUE, 0);
+	g_signal_connect(G_OBJECT(tabs),"destroy",
+			 G_CALLBACK(config_destroyed), NULL);
 
 	/* Options tab */
 	options_tab = gkrellm_create_tab(tabs, _("Options"));
@@ -346,6 +397,10 @@
 							(GtkDestroyNotify) gtk_widget_unref);
 	gtk_widget_show (prog_entry);
 	gtk_box_pack_start (GTK_BOX (prog_box), prog_entry, TRUE, TRUE, 0);
+	g_signal_connect(G_OBJECT(prog_entry), "activate",
+				G_CALLBACK(cb_prog_entry), GINT_TO_POINTER(1));
+	g_signal_connect(G_OBJECT(prog_entry), "changed",
+				G_CALLBACK(cb_prog_entry), GINT_TO_POINTER(0));
 
 	row1 = gtk_hbox_new (FALSE, 0);
 	gtk_widget_set_name (row1, "row1");
@@ -470,6 +525,11 @@
 	gtk_widget_show (fish_traffic_check);
 	gtk_box_pack_start (GTK_BOX (fish_traffic_box), fish_traffic_check, TRUE, TRUE, 0);
 
+	gkrellm_gtk_spin_button(main_box, NULL, update_interval,
+				10.0, 50.0, 1.0, 5.0, 0, 60,
+				cb_interval_modified, NULL, FALSE,
+				_("Updates per second"));
+
 	setup_toggle_buttons();
 
 	gtk_signal_connect(GTK_OBJECT(cpu_check), "toggled", GTK_SIGNAL_FUNC(option_toggled_cb), NULL);
@@ -494,15 +554,6 @@
 
 }
 
-static void
-apply_plugin_config(void)
-{
-	if(prog)
-	{
-		g_free(prog);
-	}
-	prog = g_strdup(gtk_editable_get_chars(GTK_EDITABLE(prog_entry), 0, -1));
-}
 
 static void
 save_plugin_config(FILE *f)
@@ -511,13 +562,15 @@
 	{
 		fprintf(f, "%s prog %s\n", PLUGIN_KEYWORD, prog);
 	}
-	fprintf(f, "%s options %d.%d.%d.%d.%d.%d\n", PLUGIN_KEYWORD,
+	fprintf(f, "%s options %d.%d.%d.%d.%d.%d.%d\n", PLUGIN_KEYWORD,
 			cpu_enabled,
 			duck_enabled,
 			memscreen_enabled,
 			fish_enabled,
 			fish_traffic,
-			time_enabled);
+			time_enabled,
+			update_interval);
+
 }
 
 static void
@@ -539,13 +592,14 @@
 	}
 	else if(!strcmp(config_item, "options"))
 	{
-		sscanf(value, "%d.%d.%d.%d.%d.%d",
+		sscanf(value, "%d.%d.%d.%d.%d.%d.%d",
 				&cpu_enabled,
 				&duck_enabled,
 				&memscreen_enabled,
 				&fish_enabled,
 				&fish_traffic,
-				&time_enabled);
+				&time_enabled,
+				&update_interval);
 	}
 
 }
@@ -556,9 +610,9 @@
 	PLUGIN_NAME,         /* Name, for config tab.                    */
 	0,                   /* Id,  0 if a plugin                       */
 	create_plugin,       /* The create_plugin() function             */
-	update_plugin,       /* The update_plugin() function             */
+	NULL,                /* The update_plugin() function             */
 	create_plugin_tab,   /* The create_plugin_tab() config function  */
-	apply_plugin_config, /* The apply_plugin_config() function       */
+	NULL,                /* The apply_plugin_config() function       */
 	
 	save_plugin_config,  /* The save_plugin_config() function        */
 	load_plugin_config,  /* The load_plugin_config() function        */
@@ -577,6 +631,7 @@
 Monitor *
 init_plugin(void)
 {
+	update_interval = 20;
 	style_id = gkrellm_add_meter_style(&bfm_mon, PLUGIN_STYLE);
 	return (mon = &bfm_mon);
 }
