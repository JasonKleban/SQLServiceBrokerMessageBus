namespace SSBMBManager
{
    partial class Main
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.gbConfiguration = new System.Windows.Forms.GroupBox();
            this.btnRefresh = new System.Windows.Forms.Button();
            this.txtConnectionString = new System.Windows.Forms.TextBox();
            this.gbChannels = new System.Windows.Forms.GroupBox();
            this.txtChannelName = new System.Windows.Forms.TextBox();
            this.btnCreateChannel = new System.Windows.Forms.Button();
            this.btnDestroyChannel = new System.Windows.Forms.Button();
            this.lbChannels = new System.Windows.Forms.ListBox();
            this.btnInstall = new System.Windows.Forms.Button();
            this.btnUninstall = new System.Windows.Forms.Button();
            this.gbInstance = new System.Windows.Forms.GroupBox();
            this.btnRepair = new System.Windows.Forms.Button();
            this.btnScriptConfiguration = new System.Windows.Forms.Button();
            this.gbSubscriptions = new System.Windows.Forms.GroupBox();
            this.btnSubscribe = new System.Windows.Forms.Button();
            this.txtSubscriptionName = new System.Windows.Forms.TextBox();
            this.btnUnsubscribe = new System.Windows.Forms.Button();
            this.lbSubscriptions = new System.Windows.Forms.ListBox();
            this.gbTopics = new System.Windows.Forms.GroupBox();
            this.btnCleanupSubscriptions = new System.Windows.Forms.Button();
            this.txtTopicName = new System.Windows.Forms.TextBox();
            this.btnCreateTopic = new System.Windows.Forms.Button();
            this.btnDestroyTopic = new System.Windows.Forms.Button();
            this.lbTopics = new System.Windows.Forms.ListBox();
            this.gbConfiguration.SuspendLayout();
            this.gbChannels.SuspendLayout();
            this.gbInstance.SuspendLayout();
            this.gbSubscriptions.SuspendLayout();
            this.gbTopics.SuspendLayout();
            this.SuspendLayout();
            // 
            // gbConfiguration
            // 
            this.gbConfiguration.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.gbConfiguration.Controls.Add(this.btnRefresh);
            this.gbConfiguration.Controls.Add(this.txtConnectionString);
            this.gbConfiguration.Location = new System.Drawing.Point(12, 12);
            this.gbConfiguration.Name = "gbConfiguration";
            this.gbConfiguration.Size = new System.Drawing.Size(769, 49);
            this.gbConfiguration.TabIndex = 0;
            this.gbConfiguration.TabStop = false;
            this.gbConfiguration.Text = "SQL Server Connection String";
            // 
            // btnRefresh
            // 
            this.btnRefresh.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnRefresh.Location = new System.Drawing.Point(688, 17);
            this.btnRefresh.Name = "btnRefresh";
            this.btnRefresh.Size = new System.Drawing.Size(75, 23);
            this.btnRefresh.TabIndex = 0;
            this.btnRefresh.Text = "Refresh";
            this.btnRefresh.UseVisualStyleBackColor = true;
            this.btnRefresh.Click += new System.EventHandler(this.btnRefresh_Click);
            // 
            // txtConnectionString
            // 
            this.txtConnectionString.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtConnectionString.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtConnectionString.Location = new System.Drawing.Point(7, 20);
            this.txtConnectionString.Name = "txtConnectionString";
            this.txtConnectionString.Size = new System.Drawing.Size(675, 25);
            this.txtConnectionString.TabIndex = 0;
            this.txtConnectionString.Text = "data source=.;initial catalog=temp;integrated security=True;MultipleActiveResultSets=True;";
            this.txtConnectionString.TextChanged += new System.EventHandler(this.txtConnectionString_TextChanged);
            // 
            // gbChannels
            // 
            this.gbChannels.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left)));
            this.gbChannels.Controls.Add(this.txtChannelName);
            this.gbChannels.Controls.Add(this.btnCreateChannel);
            this.gbChannels.Controls.Add(this.btnDestroyChannel);
            this.gbChannels.Controls.Add(this.lbChannels);
            this.gbChannels.Location = new System.Drawing.Point(12, 67);
            this.gbChannels.Name = "gbChannels";
            this.gbChannels.Size = new System.Drawing.Size(381, 628);
            this.gbChannels.TabIndex = 1;
            this.gbChannels.TabStop = false;
            this.gbChannels.Text = "Channels";
            // 
            // txtChannelName
            // 
            this.txtChannelName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtChannelName.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtChannelName.Location = new System.Drawing.Point(123, 598);
            this.txtChannelName.Name = "txtChannelName";
            this.txtChannelName.Size = new System.Drawing.Size(141, 25);
            this.txtChannelName.TabIndex = 4;
            this.txtChannelName.TextChanged += new System.EventHandler(this.txtChannelName_TextChanged);
            // 
            // btnCreateChannel
            // 
            this.btnCreateChannel.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnCreateChannel.Location = new System.Drawing.Point(270, 599);
            this.btnCreateChannel.Name = "btnCreateChannel";
            this.btnCreateChannel.Size = new System.Drawing.Size(105, 23);
            this.btnCreateChannel.TabIndex = 3;
            this.btnCreateChannel.Text = "Create Channel";
            this.btnCreateChannel.UseVisualStyleBackColor = true;
            this.btnCreateChannel.Click += new System.EventHandler(this.btnCreateChannel_Click);
            // 
            // btnDestroyChannel
            // 
            this.btnDestroyChannel.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnDestroyChannel.Location = new System.Drawing.Point(7, 599);
            this.btnDestroyChannel.Name = "btnDestroyChannel";
            this.btnDestroyChannel.Size = new System.Drawing.Size(110, 23);
            this.btnDestroyChannel.TabIndex = 1;
            this.btnDestroyChannel.Text = "Destroy Channel";
            this.btnDestroyChannel.UseVisualStyleBackColor = true;
            this.btnDestroyChannel.Click += new System.EventHandler(this.btnDestroyChannel_Click);
            // 
            // lbChannels
            // 
            this.lbChannels.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.lbChannels.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lbChannels.FormattingEnabled = true;
            this.lbChannels.IntegralHeight = false;
            this.lbChannels.ItemHeight = 18;
            this.lbChannels.Location = new System.Drawing.Point(7, 19);
            this.lbChannels.Name = "lbChannels";
            this.lbChannels.Size = new System.Drawing.Size(368, 572);
            this.lbChannels.TabIndex = 0;
            this.lbChannels.SelectedIndexChanged += new System.EventHandler(this.lbChannels_SelectedIndexChanged);
            // 
            // btnInstall
            // 
            this.btnInstall.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnInstall.Enabled = false;
            this.btnInstall.Location = new System.Drawing.Point(8, 17);
            this.btnInstall.Name = "btnInstall";
            this.btnInstall.Size = new System.Drawing.Size(75, 23);
            this.btnInstall.TabIndex = 2;
            this.btnInstall.Text = "Install";
            this.btnInstall.UseVisualStyleBackColor = true;
            this.btnInstall.Click += new System.EventHandler(this.btnInstall_Click);
            // 
            // btnUninstall
            // 
            this.btnUninstall.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnUninstall.Enabled = false;
            this.btnUninstall.Location = new System.Drawing.Point(170, 17);
            this.btnUninstall.Name = "btnUninstall";
            this.btnUninstall.Size = new System.Drawing.Size(75, 23);
            this.btnUninstall.TabIndex = 3;
            this.btnUninstall.Text = "Uninstall";
            this.btnUninstall.UseVisualStyleBackColor = true;
            this.btnUninstall.Click += new System.EventHandler(this.btnUninstall_Click);
            // 
            // gbInstance
            // 
            this.gbInstance.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.gbInstance.Controls.Add(this.btnRepair);
            this.gbInstance.Controls.Add(this.btnScriptConfiguration);
            this.gbInstance.Controls.Add(this.btnInstall);
            this.gbInstance.Controls.Add(this.btnUninstall);
            this.gbInstance.Location = new System.Drawing.Point(787, 12);
            this.gbInstance.Name = "gbInstance";
            this.gbInstance.Size = new System.Drawing.Size(389, 49);
            this.gbInstance.TabIndex = 4;
            this.gbInstance.TabStop = false;
            this.gbInstance.Text = "Instance Control";
            // 
            // btnRepair
            // 
            this.btnRepair.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnRepair.Location = new System.Drawing.Point(89, 17);
            this.btnRepair.Name = "btnRepair";
            this.btnRepair.Size = new System.Drawing.Size(75, 23);
            this.btnRepair.TabIndex = 5;
            this.btnRepair.Text = "Repair";
            this.btnRepair.UseVisualStyleBackColor = true;
            this.btnRepair.Click += new System.EventHandler(this.btnRepair_Click);
            // 
            // btnScriptConfiguration
            // 
            this.btnScriptConfiguration.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnScriptConfiguration.Enabled = false;
            this.btnScriptConfiguration.Location = new System.Drawing.Point(251, 17);
            this.btnScriptConfiguration.Name = "btnScriptConfiguration";
            this.btnScriptConfiguration.Size = new System.Drawing.Size(132, 23);
            this.btnScriptConfiguration.TabIndex = 4;
            this.btnScriptConfiguration.Text = "Script Configuration";
            this.btnScriptConfiguration.UseVisualStyleBackColor = true;
            this.btnScriptConfiguration.Click += new System.EventHandler(this.btnScriptConfiguration_Click);
            // 
            // gbSubscriptions
            // 
            this.gbSubscriptions.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.gbSubscriptions.Controls.Add(this.btnSubscribe);
            this.gbSubscriptions.Controls.Add(this.txtSubscriptionName);
            this.gbSubscriptions.Controls.Add(this.btnUnsubscribe);
            this.gbSubscriptions.Controls.Add(this.lbSubscriptions);
            this.gbSubscriptions.Location = new System.Drawing.Point(399, 369);
            this.gbSubscriptions.Name = "gbSubscriptions";
            this.gbSubscriptions.Size = new System.Drawing.Size(777, 326);
            this.gbSubscriptions.TabIndex = 5;
            this.gbSubscriptions.TabStop = false;
            this.gbSubscriptions.Text = "Subscriptions";
            // 
            // btnSubscribe
            // 
            this.btnSubscribe.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSubscribe.Location = new System.Drawing.Point(696, 297);
            this.btnSubscribe.Name = "btnSubscribe";
            this.btnSubscribe.Size = new System.Drawing.Size(75, 23);
            this.btnSubscribe.TabIndex = 7;
            this.btnSubscribe.Text = "Subscribe";
            this.btnSubscribe.UseVisualStyleBackColor = true;
            this.btnSubscribe.Click += new System.EventHandler(this.btnSubscribe_Click);
            // 
            // txtSubscriptionName
            // 
            this.txtSubscriptionName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtSubscriptionName.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtSubscriptionName.Location = new System.Drawing.Point(87, 295);
            this.txtSubscriptionName.Name = "txtSubscriptionName";
            this.txtSubscriptionName.Size = new System.Drawing.Size(603, 25);
            this.txtSubscriptionName.TabIndex = 6;
            this.txtSubscriptionName.TextChanged += new System.EventHandler(this.txtSubscriptionName_TextChanged);
            // 
            // btnUnsubscribe
            // 
            this.btnUnsubscribe.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnUnsubscribe.Location = new System.Drawing.Point(6, 296);
            this.btnUnsubscribe.Name = "btnUnsubscribe";
            this.btnUnsubscribe.Size = new System.Drawing.Size(75, 23);
            this.btnUnsubscribe.TabIndex = 5;
            this.btnUnsubscribe.Text = "Unsubscribe";
            this.btnUnsubscribe.UseVisualStyleBackColor = true;
            this.btnUnsubscribe.Click += new System.EventHandler(this.btnUnsubscribe_Click);
            // 
            // lbSubscriptions
            // 
            this.lbSubscriptions.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.lbSubscriptions.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lbSubscriptions.FormattingEnabled = true;
            this.lbSubscriptions.IntegralHeight = false;
            this.lbSubscriptions.ItemHeight = 18;
            this.lbSubscriptions.Location = new System.Drawing.Point(6, 19);
            this.lbSubscriptions.Name = "lbSubscriptions";
            this.lbSubscriptions.Size = new System.Drawing.Size(765, 270);
            this.lbSubscriptions.TabIndex = 0;
            this.lbSubscriptions.SelectedIndexChanged += new System.EventHandler(this.lbSubscriptions_SelectedIndexChanged);
            // 
            // gbTopics
            // 
            this.gbTopics.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.gbTopics.Controls.Add(this.btnCleanupSubscriptions);
            this.gbTopics.Controls.Add(this.txtTopicName);
            this.gbTopics.Controls.Add(this.btnCreateTopic);
            this.gbTopics.Controls.Add(this.btnDestroyTopic);
            this.gbTopics.Controls.Add(this.lbTopics);
            this.gbTopics.Location = new System.Drawing.Point(399, 67);
            this.gbTopics.Name = "gbTopics";
            this.gbTopics.Size = new System.Drawing.Size(777, 296);
            this.gbTopics.TabIndex = 6;
            this.gbTopics.TabStop = false;
            this.gbTopics.Text = "Topics";
            // 
            // btnCleanupSubscriptions
            // 
            this.btnCleanupSubscriptions.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnCleanupSubscriptions.Location = new System.Drawing.Point(6, 266);
            this.btnCleanupSubscriptions.Name = "btnCleanupSubscriptions";
            this.btnCleanupSubscriptions.Size = new System.Drawing.Size(132, 23);
            this.btnCleanupSubscriptions.TabIndex = 4;
            this.btnCleanupSubscriptions.Text = "Cleanup Subscriptions";
            this.btnCleanupSubscriptions.UseVisualStyleBackColor = true;
            this.btnCleanupSubscriptions.Click += new System.EventHandler(this.btnCleanupSubscriptions_Click);
            // 
            // txtTopicName
            // 
            this.txtTopicName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtTopicName.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtTopicName.Location = new System.Drawing.Point(256, 266);
            this.txtTopicName.Name = "txtTopicName";
            this.txtTopicName.Size = new System.Drawing.Size(403, 25);
            this.txtTopicName.TabIndex = 3;
            this.txtTopicName.TextChanged += new System.EventHandler(this.txtTopicName_TextChanged);
            // 
            // btnCreateTopic
            // 
            this.btnCreateTopic.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnCreateTopic.Location = new System.Drawing.Point(665, 266);
            this.btnCreateTopic.Name = "btnCreateTopic";
            this.btnCreateTopic.Size = new System.Drawing.Size(106, 23);
            this.btnCreateTopic.TabIndex = 2;
            this.btnCreateTopic.Text = "Create Topic";
            this.btnCreateTopic.UseVisualStyleBackColor = true;
            this.btnCreateTopic.Click += new System.EventHandler(this.btnCreateTopic_Click);
            // 
            // btnDestroyTopic
            // 
            this.btnDestroyTopic.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnDestroyTopic.Location = new System.Drawing.Point(144, 266);
            this.btnDestroyTopic.Name = "btnDestroyTopic";
            this.btnDestroyTopic.Size = new System.Drawing.Size(106, 23);
            this.btnDestroyTopic.TabIndex = 1;
            this.btnDestroyTopic.Text = "Destroy Topic";
            this.btnDestroyTopic.UseVisualStyleBackColor = true;
            this.btnDestroyTopic.Click += new System.EventHandler(this.btnDestroyTopic_Click);
            // 
            // lbTopics
            // 
            this.lbTopics.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.lbTopics.Font = new System.Drawing.Font("Consolas", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lbTopics.FormattingEnabled = true;
            this.lbTopics.IntegralHeight = false;
            this.lbTopics.ItemHeight = 18;
            this.lbTopics.Location = new System.Drawing.Point(6, 19);
            this.lbTopics.Name = "lbTopics";
            this.lbTopics.Size = new System.Drawing.Size(765, 241);
            this.lbTopics.TabIndex = 0;
            this.lbTopics.SelectedIndexChanged += new System.EventHandler(this.lbTopics_SelectedIndexChanged);
            // 
            // Main
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1188, 707);
            this.Controls.Add(this.gbTopics);
            this.Controls.Add(this.gbSubscriptions);
            this.Controls.Add(this.gbInstance);
            this.Controls.Add(this.gbChannels);
            this.Controls.Add(this.gbConfiguration);
            this.Name = "Main";
            this.Text = "SQL Service Broker Message Bus Manager";
            this.gbConfiguration.ResumeLayout(false);
            this.gbConfiguration.PerformLayout();
            this.gbChannels.ResumeLayout(false);
            this.gbChannels.PerformLayout();
            this.gbInstance.ResumeLayout(false);
            this.gbSubscriptions.ResumeLayout(false);
            this.gbSubscriptions.PerformLayout();
            this.gbTopics.ResumeLayout(false);
            this.gbTopics.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.GroupBox gbConfiguration;
        private System.Windows.Forms.TextBox txtConnectionString;
        private System.Windows.Forms.GroupBox gbChannels;
        private System.Windows.Forms.Button btnRefresh;
        private System.Windows.Forms.Button btnUninstall;
        private System.Windows.Forms.Button btnInstall;
        private System.Windows.Forms.GroupBox gbInstance;
        private System.Windows.Forms.TextBox txtChannelName;
        private System.Windows.Forms.Button btnCreateChannel;
        private System.Windows.Forms.Button btnDestroyChannel;
        private System.Windows.Forms.ListBox lbChannels;
        private System.Windows.Forms.GroupBox gbSubscriptions;
        private System.Windows.Forms.ListBox lbSubscriptions;
        private System.Windows.Forms.Button btnScriptConfiguration;
        private System.Windows.Forms.GroupBox gbTopics;
        private System.Windows.Forms.TextBox txtTopicName;
        private System.Windows.Forms.Button btnCreateTopic;
        private System.Windows.Forms.Button btnDestroyTopic;
        private System.Windows.Forms.ListBox lbTopics;
        private System.Windows.Forms.Button btnUnsubscribe;
        private System.Windows.Forms.Button btnSubscribe;
        private System.Windows.Forms.TextBox txtSubscriptionName;
        private System.Windows.Forms.Button btnCleanupSubscriptions;
        private System.Windows.Forms.Button btnRepair;
    }
}

