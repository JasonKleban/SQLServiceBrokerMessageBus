using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SSBMBManager
{
    public partial class Main : Form
    {
        public Main()
        {
            InitializeComponent();

            Reset();
        }

        private void Reset()
        {
            gbInstance.Text = "Instance Control";
            btnScriptConfiguration.Enabled = false;
            btnRepair.Enabled = false;
            btnInstall.Enabled = false;
            btnUninstall.Enabled = false;
            btnDestroyChannel.Enabled = false;
            btnCreateChannel.Enabled = false;
            btnDestroyTopic.Enabled = false;
            btnCreateTopic.Enabled = false;
            btnCleanupSubscriptions.Enabled = false;
            lbChannels.Items.Clear();
            lbTopics.Items.Clear();
            txtChannelName.Text = "";
            txtTopicName.Text = "";

            ResetSubscriptions();
        }

        private void ResetSubscriptions()
        {
            lbSubscriptions.Items.Clear();
            btnSubscribe.Enabled = false;
            btnUnsubscribe.Enabled = false;
            txtSubscriptionName.Text = "";
        }

        private void RefreshFromConn()
        {
            try
            {
                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    btnScriptConfiguration.Enabled = true;

                    if (SSBMB.InstanceManager.IsInstalled(conn))
                    {
                        gbInstance.Text = "Instance Control (Installed)";
                        btnInstall.Enabled = false;

                        lbChannels.Items.AddRange(SSBMB.ChannelManager.ListChannels(conn).ToArray());
                        lbTopics.Items.AddRange(SSBMB.TopicManager.ListTopics(conn).ToArray());
                        btnCleanupSubscriptions.Enabled = true;

                        var topicName = 0 <= lbChannels.SelectedIndex ? (string)lbTopics.SelectedItem : null;

                        lbSubscriptions.Items.AddRange(SSBMB.SubscriptionManager.ListSubscriptions(conn)
                            .Where(s => topicName == null || string.Compare(s.Topic, topicName, StringComparison.OrdinalIgnoreCase) == 0).ToArray());
                    }
                    else
                    {
                        gbInstance.Text = "Instance Control (Not Installed)";
                        btnInstall.Enabled = true;
                    }

                    if (SSBMB.InstanceManager.MayUninstall(conn))
                    {
                        btnUninstall.Enabled = true;
                    }
                    else
                    {
                        btnUninstall.Enabled = false;
                    }

                    if (SSBMB.InstanceManager.MayRepair(conn))
                    {
                        btnRepair.Enabled = true;
                    }
                    else
                    {
                        btnRepair.Enabled = false;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnRefresh_Click(object sender, EventArgs e)
        {
            RefreshFromConn();
        }

        private void txtConnectionString_TextChanged(object sender, EventArgs e)
        {
            Reset();
        }

        private void txtChannelName_TextChanged(object sender, EventArgs e)
        {
            btnDestroyChannel.Enabled = txtChannelName.Text != "";
            btnCreateChannel.Enabled = txtChannelName.Text != "";
        }

        private void btnInstall_Click(object sender, EventArgs e)
        {
            try
            {
                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.InstanceManager.Install(conn);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnUninstall_Click(object sender, EventArgs e)
        {
            try
            {
                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.InstanceManager.Uninstall(conn);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnCreateChannel_Click(object sender, EventArgs e)
        {
            try
            {
                var channelName = txtChannelName.Text;

                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.ChannelManager.CreateChannel(conn, channelName);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnDestroyChannel_Click(object sender, EventArgs e)
        {
            try
            {
                var channelName = txtChannelName.Text;

                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.ChannelManager.DestroyChannel(conn, channelName);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void lbChannels_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (0 <= lbChannels.SelectedIndex)
            {
                txtChannelName.Text = (string)lbChannels.SelectedItem;
                btnDestroyChannel.Enabled = true;
                btnCreateChannel.Enabled = true;
            }
            else
            {
                txtChannelName.Text = "";
                btnDestroyChannel.Enabled = false;
                btnCreateChannel.Enabled = false;
            }
        }

        private void btnScriptConfiguration_Click(object sender, EventArgs e)
        {
            using (var conn = new SqlConnection(txtConnectionString.Text))
            {
                conn.Open();

                System.Windows.Forms.Clipboard.SetText(SSBMB.InstanceManager.ScriptAll(conn));
                MessageBox.Show("Configuration script is now in your clipboard", "Copied", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void lbTopics_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (0 <= lbTopics.SelectedIndex)
            {
                txtTopicName.Text = (string)lbTopics.SelectedItem;
                btnDestroyTopic.Enabled = true;
                btnCreateTopic.Enabled = true;

                try
                {
                    ResetSubscriptions();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            else
            {
                txtTopicName.Text = "";
                btnDestroyTopic.Enabled = false;
                btnCreateTopic.Enabled = false;

                try
                {
                    ResetSubscriptions();
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }

            var topicName = 0 <= lbChannels.SelectedIndex ? (string)lbTopics.SelectedItem : null;

            using (var conn = new SqlConnection(txtConnectionString.Text))
            {
                conn.Open();

                lbSubscriptions.Items.AddRange(SSBMB.SubscriptionManager.ListSubscriptions(conn)
                    .Where(s => topicName == null || string.Compare(s.Topic, topicName, StringComparison.OrdinalIgnoreCase) == 0).ToArray());
            }
        }

        private void lbSubscriptions_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (0 <= lbSubscriptions.SelectedIndex)
            {
                txtSubscriptionName.Text = ((SSBMB.SubscriptionDescription)lbSubscriptions.SelectedItem).Name;

                btnUnsubscribe.Enabled = ((SSBMB.SubscriptionDescription)lbSubscriptions.Items[lbSubscriptions.SelectedIndex]).Fixed;
                btnSubscribe.Enabled = ((SSBMB.SubscriptionDescription)lbSubscriptions.Items[lbSubscriptions.SelectedIndex]).Fixed;
            }
            else
            {
                txtSubscriptionName.Text = "";
                btnUnsubscribe.Enabled = false;
                btnSubscribe.Enabled = false;
            }
        }

        private void txtTopicName_TextChanged(object sender, EventArgs e)
        {
            btnDestroyTopic.Enabled = txtTopicName.Text != "";
            btnCreateTopic.Enabled = txtTopicName.Text != "";
        }

        private void txtSubscriptionName_TextChanged(object sender, EventArgs e)
        {
            btnUnsubscribe.Enabled = txtSubscriptionName.Text != "" && 0 <= lbTopics.SelectedIndex;
            btnSubscribe.Enabled = txtSubscriptionName.Text != "" && 0 <= lbTopics.SelectedIndex;
        }

        private void btnDestroyTopic_Click(object sender, EventArgs e)
        {
            try
            {
                var topicName = txtTopicName.Text;

                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.TopicManager.DestroyTopic(conn, topicName);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnCreateTopic_Click(object sender, EventArgs e)
        {
            try
            {
                var topicName = txtTopicName.Text;

                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.TopicManager.CreateTopic(conn, topicName);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnUnsubscribe_Click(object sender, EventArgs e)
        {
            try
            {
                var subscription = lbSubscriptions.SelectedItem as SSBMB.SubscriptionDescription;

                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.SubscriptionManager.Unsubscribe(conn, subscription.Topic, subscription.Name);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnSubscribe_Click(object sender, EventArgs e)
        {
            try
            {
                var topicName = (string)lbTopics.SelectedItem;
                var subscriptionName = txtSubscriptionName.Text;

                Reset();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.SubscriptionManager.Subscribe(conn, topicName, subscriptionName);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnCleanupSubscriptions_Click(object sender, EventArgs e)
        {
            try
            {
                var topicName = 0 <= lbChannels.SelectedIndex ? (string)lbTopics.SelectedItem : null;

                ResetSubscriptions();

                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.SubscriptionManager.CleanupSubscriptions(conn, topicName);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }

        private void btnRepair_Click(object sender, EventArgs e)
        {
            try
            {
                using (var conn = new SqlConnection(txtConnectionString.Text))
                {
                    conn.Open();

                    SSBMB.InstanceManager.Repair(conn);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                RefreshFromConn();
            }
        }
    }
}